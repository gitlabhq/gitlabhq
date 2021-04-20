<script>
import { GlAlert } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { __ } from '~/locale';
import {
  PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START,
  PIPELINES_DETAIL_LINKS_MARK_CALCULATE_END,
  PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
  PIPELINES_DETAIL_LINK_DURATION,
  PIPELINES_DETAIL_LINKS_TOTAL,
  PIPELINES_DETAIL_LINKS_JOB_RATIO,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { reportToSentry } from '../../utils';
import { parseData } from '../parsing_utils';
import { reportPerformance } from './api';
import LinksInner from './links_inner.vue';

export default {
  name: 'LinksLayer',
  components: {
    GlAlert,
    LinksInner,
  },
  MAX_GROUPS: 200,
  props: {
    containerMeasurements: {
      type: Object,
      required: true,
    },
    pipelineData: {
      type: Array,
      required: true,
    },
    metricsConfig: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    neverShowLinks: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      alertDismissed: false,
      showLinksOverride: false,
    };
  },
  i18n: {
    showLinksAnyways: __('Show links anyways'),
    tooManyJobs: __(
      'This graph has a large number of jobs and showing the links between them may have performance implications.',
    ),
  },
  computed: {
    containerZero() {
      return !this.containerMeasurements.width || !this.containerMeasurements.height;
    },
    numGroups() {
      return this.pipelineData.reduce((acc, { groups }) => {
        return acc + Number(groups.length);
      }, 0);
    },
    shouldCollectMetrics() {
      return this.metricsConfig.collectMetrics && this.metricsConfig.path;
    },
    showAlert() {
      /*
        This is a hard override that allows us to turn off the links without
        needing to remove the component entirely for iteration or based on graph type.
      */
      if (this.neverShowLinks) {
        return false;
      }

      return !this.containerZero && !this.showLinkedLayers && !this.alertDismissed;
    },
    showLinkedLayers() {
      /*
        This is a hard override that allows us to turn off the links without
        needing to remove the component entirely for iteration or based on graph type.
      */
      if (this.neverShowLinks) {
        return false;
      }

      return (
        !this.containerZero && (this.showLinksOverride || this.numGroups < this.$options.MAX_GROUPS)
      );
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  mounted() {
    /*
      This is code to get metrics for the graph (to observe links performance).
      It is currently here because we want values for links without drawing them.
      It can be removed when https://gitlab.com/gitlab-org/gitlab/-/issues/298930
      is closed and functionality is enabled by default.
    */

    if (this.neverShowLinks && !isEmpty(this.pipelineData)) {
      window.requestAnimationFrame(() => {
        this.prepareLinkData();
      });
    }
  },
  methods: {
    beginPerfMeasure() {
      if (this.shouldCollectMetrics) {
        performanceMarkAndMeasure({ mark: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START });
      }
    },
    finishPerfMeasureAndSend(numLinks) {
      if (this.shouldCollectMetrics) {
        performanceMarkAndMeasure({
          mark: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_END,
          measures: [
            {
              name: PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
              start: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START,
            },
          ],
        });
      }

      window.requestAnimationFrame(() => {
        const duration = window.performance.getEntriesByName(
          PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
        )[0]?.duration;

        if (!duration) {
          return;
        }

        const data = {
          histograms: [
            { name: PIPELINES_DETAIL_LINK_DURATION, value: duration / 1000 },
            { name: PIPELINES_DETAIL_LINKS_TOTAL, value: numLinks },
            {
              name: PIPELINES_DETAIL_LINKS_JOB_RATIO,
              value: numLinks / this.numGroups,
            },
          ],
        };

        reportPerformance(this.metricsConfig.path, data);
      });
    },
    dismissAlert() {
      this.alertDismissed = true;
    },
    overrideShowLinks() {
      this.dismissAlert();
      this.showLinksOverride = true;
    },
    prepareLinkData() {
      this.beginPerfMeasure();
      let numLinks;
      try {
        const arrayOfJobs = this.pipelineData.flatMap(({ groups }) => groups);
        numLinks = parseData(arrayOfJobs).links.length;
      } catch (err) {
        reportToSentry(this.$options.name, err);
      }
      this.finishPerfMeasureAndSend(numLinks);
    },
  },
};
</script>
<template>
  <links-inner
    v-if="showLinkedLayers"
    :container-measurements="containerMeasurements"
    :pipeline-data="pipelineData"
    :total-groups="numGroups"
    :metrics-config="metricsConfig"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <slot></slot>
  </links-inner>
  <div v-else>
    <gl-alert
      v-if="showAlert"
      class="gl-ml-4 gl-mb-4"
      :primary-button-text="$options.i18n.showLinksAnyways"
      @primaryAction="overrideShowLinks"
      @dismiss="dismissAlert"
    >
      {{ $options.i18n.tooManyJobs }}
    </gl-alert>
    <div class="gl-display-flex gl-relative">
      <slot></slot>
    </div>
  </div>
</template>
