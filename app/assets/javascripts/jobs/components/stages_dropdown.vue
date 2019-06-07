<script>
import _ from 'underscore';
import { GlLink } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import PipelineLink from '~/vue_shared/components/ci_pipeline_link.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    CiIcon,
    Icon,
    GlLink,
    PipelineLink,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    stages: {
      type: Array,
      required: true,
    },
    selectedStage: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasRef() {
      return !_.isEmpty(this.pipeline.ref);
    },
    isTriggeredByMergeRequest() {
      return Boolean(this.pipeline.merge_request);
    },
    isMergeRequestPipeline() {
      return Boolean(this.pipeline.flags && this.pipeline.flags.merge_request_pipeline);
    },
  },
  methods: {
    onStageClick(stage) {
      this.$emit('requestSidebarStageDropdown', stage);
    },
  },
};
</script>
<template>
  <div class="block-last dropdown">
    <div class="js-pipeline-info">
      <ci-icon :status="pipeline.details.status" class="vertical-align-middle" />

      <span class="font-weight-bold">{{ s__('Job|Pipeline') }}</span>
      <pipeline-link
        :href="pipeline.path"
        :pipeline-id="pipeline.id"
        :pipeline-iid="pipeline.iid"
        class="js-pipeline-path link-commit qa-pipeline-path"
      />
      <template v-if="hasRef">
        {{ s__('Job|for') }}

        <template v-if="isTriggeredByMergeRequest">
          <gl-link :href="pipeline.merge_request.path" class="link-commit ref-name js-mr-link"
            >!{{ pipeline.merge_request.iid }}</gl-link
          >
          {{ s__('Job|with') }}
          <gl-link
            :href="pipeline.merge_request.source_branch_path"
            class="link-commit ref-name js-source-branch-link"
            >{{ pipeline.merge_request.source_branch }}</gl-link
          >

          <template v-if="isMergeRequestPipeline">
            {{ s__('Job|into') }}
            <gl-link
              :href="pipeline.merge_request.target_branch_path"
              class="link-commit ref-name js-target-branch-link"
              >{{ pipeline.merge_request.target_branch }}</gl-link
            >
          </template>
        </template>
        <gl-link v-else :href="pipeline.ref.path" class="link-commit ref-name">{{
          pipeline.ref.name
        }}</gl-link>
      </template>
    </div>

    <button
      type="button"
      data-toggle="dropdown"
      class="js-selected-stage dropdown-menu-toggle prepend-top-8"
    >
      {{ selectedStage }} <i class="fa fa-chevron-down"></i>
    </button>

    <ul class="dropdown-menu">
      <li v-for="stage in stages" :key="stage.name">
        <button type="button" class="js-stage-item stage-item" @click="onStageClick(stage)">
          {{ stage.name }}
        </button>
      </li>
    </ul>
  </div>
</template>
