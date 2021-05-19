<script>
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
    LinksInner,
  },
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
    showLinks: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      alertDismissed: false,
      parsedData: {},
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
    showLinkedLayers() {
      return this.showLinks && !this.containerZero;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  mounted() {
    if (!isEmpty(this.pipelineData)) {
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
    prepareLinkData() {
      this.beginPerfMeasure();
      let numLinks;
      try {
        const arrayOfJobs = this.pipelineData.flatMap(({ groups }) => groups);
        this.parsedData = parseData(arrayOfJobs);
        numLinks = this.parsedData.links.length;
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
    :parsed-data="parsedData"
    :pipeline-data="pipelineData"
    :total-groups="numGroups"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <slot></slot>
  </links-inner>
  <div v-else>
    <div class="gl-display-flex gl-relative">
      <slot></slot>
    </div>
  </div>
</template>
