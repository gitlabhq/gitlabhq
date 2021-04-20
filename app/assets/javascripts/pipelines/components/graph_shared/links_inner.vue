<script>
import { isEmpty } from 'lodash';
import {
  PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START,
  PIPELINES_DETAIL_LINKS_MARK_CALCULATE_END,
  PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
  PIPELINES_DETAIL_LINK_DURATION,
  PIPELINES_DETAIL_LINKS_TOTAL,
  PIPELINES_DETAIL_LINKS_JOB_RATIO,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { DRAW_FAILURE } from '../../constants';
import { createJobsHash, generateJobNeedsDict, reportToSentry } from '../../utils';
import { STAGE_VIEW } from '../graph/constants';
import { parseData } from '../parsing_utils';
import { reportPerformance } from './api';
import { generateLinksData } from './drawing_utils';

export default {
  name: 'LinksInner',
  STROKE_WIDTH: 2,
  props: {
    containerId: {
      type: String,
      required: true,
    },
    containerMeasurements: {
      type: Object,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: true,
    },
    pipelineData: {
      type: Array,
      required: true,
    },
    totalGroups: {
      type: Number,
      required: true,
    },
    metricsConfig: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    defaultLinkColor: {
      type: String,
      required: false,
      default: 'gl-stroke-gray-200',
    },
    highlightedJob: {
      type: String,
      required: false,
      default: '',
    },
    viewType: {
      type: String,
      required: false,
      default: STAGE_VIEW,
    },
  },
  data() {
    return {
      links: [],
      needsObject: null,
      parsedData: {},
    };
  },
  computed: {
    shouldCollectMetrics() {
      return this.metricsConfig.collectMetrics && this.metricsConfig.path;
    },
    hasHighlightedJob() {
      return Boolean(this.highlightedJob);
    },
    isPipelineDataEmpty() {
      return isEmpty(this.pipelineData);
    },
    highlightedJobs() {
      // If you are hovering on a job, then the jobs we want to highlight are:
      // The job you are currently hovering + all of its needs.
      return this.hasHighlightedJob
        ? [this.highlightedJob, ...this.needsObject[this.highlightedJob]]
        : [];
    },
    highlightedLinks() {
      // If you are hovering on a job, then the links we want to highlight are:
      // All the links whose `source` and `target` are highlighted jobs.
      if (this.hasHighlightedJob) {
        const filteredLinks = this.links.filter((link) => {
          return (
            this.highlightedJobs.includes(link.source) && this.highlightedJobs.includes(link.target)
          );
        });

        return filteredLinks.map((link) => link.ref);
      }

      return [];
    },
    viewBox() {
      return [0, 0, this.containerMeasurements.width, this.containerMeasurements.height];
    },
  },
  watch: {
    highlightedJob() {
      // On first hover, generate the needs reference
      if (!this.needsObject) {
        const jobs = createJobsHash(this.pipelineData);
        this.needsObject = generateJobNeedsDict(jobs) ?? {};
      }
    },
    highlightedJobs(jobs) {
      this.$emit('highlightedJobsChange', jobs);
    },
    viewType() {
      /*
        We need to wait a tick so that the layout reflows
        before the links refresh.
      */
      this.$nextTick(() => {
        this.refreshLinks();
      });
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  mounted() {
    if (!isEmpty(this.pipelineData)) {
      this.prepareLinkData();
    }
  },
  methods: {
    beginPerfMeasure() {
      if (this.shouldCollectMetrics) {
        performanceMarkAndMeasure({ mark: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START });
      }
    },
    finishPerfMeasureAndSend() {
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
            { name: PIPELINES_DETAIL_LINKS_TOTAL, value: this.links.length },
            {
              name: PIPELINES_DETAIL_LINKS_JOB_RATIO,
              value: this.links.length / this.totalGroups,
            },
          ],
        };

        reportPerformance(this.metricsConfig.path, data);
      });
    },
    isLinkHighlighted(linkRef) {
      return this.highlightedLinks.includes(linkRef);
    },
    prepareLinkData() {
      this.beginPerfMeasure();
      try {
        const arrayOfJobs = this.pipelineData.flatMap(({ groups }) => groups);
        this.parsedData = parseData(arrayOfJobs);
        this.refreshLinks();
      } catch (err) {
        this.$emit('error', { type: DRAW_FAILURE, reportToSentry: false });
        reportToSentry(this.$options.name, err);
      }
      this.finishPerfMeasureAndSend();
    },
    refreshLinks() {
      this.links = generateLinksData(this.parsedData, this.containerId, `-${this.pipelineId}`);
    },
    getLinkClasses(link) {
      return [
        this.isLinkHighlighted(link.ref) ? 'gl-stroke-blue-400' : this.defaultLinkColor,
        { 'gl-opacity-3': this.hasHighlightedJob && !this.isLinkHighlighted(link.ref) },
      ];
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-relative">
    <svg
      id="link-svg"
      class="gl-absolute gl-pointer-events-none"
      :viewBox="viewBox"
      :width="`${containerMeasurements.width}px`"
      :height="`${containerMeasurements.height}px`"
    >
      <path
        v-for="link in links"
        :key="link.path"
        :ref="link.ref"
        :d="link.path"
        class="gl-fill-transparent gl-transition-duration-slow gl-transition-timing-function-ease"
        :class="getLinkClasses(link)"
        :stroke-width="$options.STROKE_WIDTH"
      />
    </svg>
    <slot></slot>
  </div>
</template>
