<script>
import { isEmpty } from 'lodash';
import { DRAW_FAILURE } from '../../constants';
import { createJobsHash, generateJobNeedsDict } from '../../utils';
import { parseData } from '../parsing_utils';
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
  },
  mounted() {
    if (!isEmpty(this.pipelineData)) {
      this.prepareLinkData();
    }
  },
  methods: {
    isLinkHighlighted(linkRef) {
      return this.highlightedLinks.includes(linkRef);
    },
    prepareLinkData() {
      try {
        const arrayOfJobs = this.pipelineData.flatMap(({ groups }) => groups);
        const parsedData = parseData(arrayOfJobs);
        this.links = generateLinksData(parsedData, this.containerId, `-${this.pipelineId}`);
      } catch {
        this.$emit('error', DRAW_FAILURE);
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
      class="gl-absolute"
      :viewBox="viewBox"
      :width="`${containerMeasurements.width}px`"
      :height="`${containerMeasurements.height}px`"
    >
      <template>
        <path
          v-for="link in links"
          :key="link.path"
          :ref="link.ref"
          :d="link.path"
          class="gl-fill-transparent gl-transition-duration-slow gl-transition-timing-function-ease"
          :class="getLinkClasses(link)"
          :stroke-width="$options.STROKE_WIDTH"
        />
      </template>
    </svg>
    <slot></slot>
  </div>
</template>
