<script>
  import CiIcon from '~/vue_shared/components/ci_icon.vue';
  import Icon from '~/vue_shared/components/icon.vue';

  import { sprintf, __ } from '~/locale';

  export default {
    components: {
      CiIcon,
      Icon,
    },
    props: {
      pipelineId: {
        type: Number,
        required: true,
      },
      pipelinePath: {
        type: String,
        required: true,
      },
      pipelineRef: {
        type: String,
        required: true,
      },
      pipelineRefPath: {
        type: String,
        required: true,
      },
      stages: {
        type: Array,
        required: true,
      },
      pipelineStatus: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        selectedStage: this.stages.length > 0 ? this.stages[0].name : __('More'),
      };
    },
    computed: {
      pipelineLink() {
        return sprintf(__('Pipeline %{pipelineLinkStart} #%{pipelineId} %{pipelineLinkEnd} from %{pipelineLinkRefStart} %{pipelineRef} %{pipelineLinkRefEnd}'), {
          pipelineLinkStart: `<a href=${this.pipelinePath} class="js-pipeline-path link-commit">`,
          pipelineId: this.pipelineId,
          pipelineLinkEnd: '</a>',
          pipelineLinkRefStart: `<a href=${this.pipelineRefPath} class="link-commit ref-name">`,
          pipelineRef: this.pipelineRef,
          pipelineLinkRefEnd: '</a>',
        }, false);
      },
    },
    methods: {
      onStageClick(stage) {
        // todo: consider moving into store
        this.selectedStage = stage.name;

        // update dropdown with jobs
        // jobs container is a new component.
        this.$emit('requestSidebarStageDropdown', stage);
      },
    },
  };
</script>
<template>
  <div class="block-last">
    <ci-icon :status="pipelineStatus" />

    <p v-html="pipelineLink"></p>

    <div class="dropdown">
      <button
        type="button"
        data-toggle="dropdown"
      >
        {{ selectedStage }}
        <icon name="chevron-down" />
      </button>
      <ul class="dropdown-menu">
        <li
          v-for="(stage, index) in stages"
          :key="index"
        >
          <button
            type="button"
            class="stage-item"
            @click="onStageClick(stage)"
          >
            {{ stage.name }}
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
