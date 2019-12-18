<script>
import { GlLoadingIcon, GlTooltipDirective, GlButton } from '@gitlab/ui';
import CiStatus from '~/vue_shared/components/ci_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlLoadingIcon,
    GlButton,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tooltipText() {
      return `${this.projectName} - ${this.pipelineStatus.label}`;
    },
    buttonId() {
      return `js-linked-pipeline-${this.pipeline.id}`;
    },
    pipelineStatus() {
      return this.pipeline.details.status;
    },
    projectName() {
      return this.pipeline.project.name;
    },
  },
  methods: {
    onClickLinkedPipeline() {
      this.$root.$emit('bv::hide::tooltip', this.buttonId);
      this.$emit('pipelineClicked');
    },
  },
};
</script>

<template>
  <li class="linked-pipeline build">
    <gl-button
      :id="buttonId"
      v-gl-tooltip
      :title="tooltipText"
      class="js-linked-pipeline-content linked-pipeline-content"
      data-qa-selector="linked_pipeline_button"
      :class="`js-pipeline-expand-${pipeline.id}`"
      @click="onClickLinkedPipeline"
    >
      <gl-loading-icon v-if="pipeline.isLoading" class="js-linked-pipeline-loading d-inline" />
      <ci-status
        v-else
        :status="pipelineStatus"
        css-classes="position-top-0"
        class="js-linked-pipeline-status"
      />
      <span class="str-truncated align-bottom"> {{ projectName }} &#8226; #{{ pipeline.id }} </span>
    </gl-button>
  </li>
</template>
