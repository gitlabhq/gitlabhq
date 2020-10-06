<script>
import { isEmpty } from 'lodash';
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import JobPill from './job_pill.vue';
import StagePill from './stage_pill.vue';
import { generateLinksData } from './drawing_utils';
import { parseData } from '../parsing_utils';
import { DRAW_FAILURE, DEFAULT } from '../../constants';
import { createUniqueJobId } from '../../utils';

export default {
  components: {
    GlAlert,
    JobPill,
    StagePill,
  },
  CONTAINER_REF: 'PIPELINE_GRAPH_CONTAINER_REF',
  CONTAINER_ID: 'pipeline-graph-container',
  STROKE_WIDTH: 2,
  errorTexts: {
    [DRAW_FAILURE]: __('Could not draw the lines for job relationships'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  props: {
    pipelineData: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      failureType: null,
      links: [],
      height: 0,
      width: 0,
    };
  },
  computed: {
    isPipelineDataEmpty() {
      return isEmpty(this.pipelineData);
    },
    hasError() {
      return this.failureType;
    },
    failure() {
      const text = this.$options.errorTexts[this.failureType] || this.$options.errorTexts[DEFAULT];

      return { text, variant: 'danger' };
    },
    viewBox() {
      return [0, 0, this.width, this.height];
    },
    lineStyle() {
      return `stroke-width:${this.$options.STROKE_WIDTH}px;`;
    },
  },
  mounted() {
    if (!this.isPipelineDataEmpty) {
      this.getGraphDimensions();
      this.drawJobLinks();
    }
  },
  methods: {
    createJobId(stageName, jobName) {
      return createUniqueJobId(stageName, jobName);
    },
    drawJobLinks() {
      const { stages, jobs } = this.pipelineData;
      const unwrappedGroups = this.unwrapPipelineData(stages);

      try {
        const parsedData = parseData(unwrappedGroups);
        this.links = generateLinksData(parsedData, jobs, this.$options.CONTAINER_ID);
      } catch {
        this.reportFailure(DRAW_FAILURE);
      }
    },
    unwrapPipelineData(stages) {
      return stages
        .map(({ name, groups }) => {
          return groups.map(group => {
            return { category: name, ...group };
          });
        })
        .flat(2);
    },
    getGraphDimensions() {
      this.width = `${this.$refs[this.$options.CONTAINER_REF].scrollWidth}px`;
      this.height = `${this.$refs[this.$options.CONTAINER_REF].scrollHeight}px`;
    },
    reportFailure(errorType) {
      this.failureType = errorType;
    },
    resetFailure() {
      this.failureType = null;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="hasError" :variant="failure.variant" @dismiss="resetFailure">
      {{ failure.text }}
    </gl-alert>
    <gl-alert v-if="isPipelineDataEmpty" variant="tip" :dismissible="false">
      {{ __('No content to show') }}
    </gl-alert>
    <div
      v-else
      :id="$options.CONTAINER_ID"
      :ref="$options.CONTAINER_REF"
      class="gl-display-flex gl-bg-gray-50 gl-px-4 gl-overflow-auto gl-relative gl-py-7"
    >
      <svg :viewBox="viewBox" :width="width" :height="height" class="gl-absolute">
        <path
          v-for="link in links"
          :key="link.path"
          :d="link.path"
          class="gl-stroke-gray-200 gl-fill-transparent"
          :style="lineStyle"
        />
      </svg>
      <div
        v-for="(stage, index) in pipelineData.stages"
        :key="`${stage.name}-${index}`"
        class="gl-flex-direction-column"
      >
        <div
          class="gl-display-flex gl-align-items-center gl-bg-white gl-w-full gl-px-8 gl-py-4 gl-mb-5"
          :class="{
            'stage-left-rounded': index === 0,
            'stage-right-rounded': index === pipelineData.stages.length - 1,
          }"
        >
          <stage-pill :stage-name="stage.name" :is-empty="stage.groups.length === 0" />
        </div>
        <div
          class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-w-full gl-px-8"
        >
          <job-pill
            v-for="group in stage.groups"
            :key="group.name"
            :job-id="createJobId(stage.name, group.name)"
            :job-name="group.name"
          />
        </div>
      </div>
    </div>
  </div>
</template>
