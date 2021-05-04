<script>
import { isEmpty } from 'lodash';
import { DRAW_FAILURE } from '../../constants';
import { createJobsHash, generateJobNeedsDict, reportToSentry } from '../../utils';
import { STAGE_VIEW } from '../graph/constants';
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
    parsedData: {
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
    };
  },
  computed: {
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
    parsedData() {
      this.calculateLinkData();
    },
    viewType() {
      /*
        We need to wait a tick so that the layout reflows
        before the links refresh.
      */
      this.$nextTick(() => {
        this.calculateLinkData();
      });
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  mounted() {
    if (!isEmpty(this.parsedData)) {
      this.calculateLinkData();
    }
  },
  methods: {
    isLinkHighlighted(linkRef) {
      return this.highlightedLinks.includes(linkRef);
    },
    calculateLinkData() {
      try {
        this.links = generateLinksData(this.parsedData, this.containerId, `-${this.pipelineId}`);
      } catch (err) {
        this.$emit('error', { type: DRAW_FAILURE, reportToSentry: false });
        reportToSentry(this.$options.name, err);
      }
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
