<script>
import { GlLink, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  components: {
    CiIcon,
    GlDropdown,
    GlDropdownItem,
    GlLink,
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
      return !isEmpty(this.pipeline.ref);
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
  <div class="dropdown">
    <div class="js-pipeline-info" data-testid="pipeline-info">
      <ci-icon :status="pipeline.details.status" class="vertical-align-middle" />

      <span class="font-weight-bold">{{ s__('Job|Pipeline') }}</span>
      <gl-link
        :href="pipeline.path"
        class="js-pipeline-path link-commit"
        data-testid="pipeline-path"
        data-qa-selector="pipeline_path"
        >#{{ pipeline.id }}</gl-link
      >
      <template v-if="hasRef">
        {{ s__('Job|for') }}

        <template v-if="isTriggeredByMergeRequest">
          <gl-link
            :href="pipeline.merge_request.path"
            class="link-commit ref-name"
            data-testid="mr-link"
            >!{{ pipeline.merge_request.iid }}</gl-link
          >
          {{ s__('Job|with') }}
          <gl-link
            :href="pipeline.merge_request.source_branch_path"
            class="link-commit ref-name"
            data-testid="source-branch-link"
            >{{ pipeline.merge_request.source_branch }}</gl-link
          >

          <template v-if="isMergeRequestPipeline">
            {{ s__('Job|into') }}
            <gl-link
              :href="pipeline.merge_request.target_branch_path"
              class="link-commit ref-name"
              data-testid="target-branch-link"
              >{{ pipeline.merge_request.target_branch }}</gl-link
            >
          </template>
        </template>
        <gl-link v-else :href="pipeline.ref.path" class="link-commit ref-name">{{
          pipeline.ref.name
        }}</gl-link>
      </template>
    </div>

    <gl-dropdown :text="selectedStage" class="js-selected-stage gl-w-full gl-mt-3">
      <gl-dropdown-item
        v-for="stage in stages"
        :key="stage.name"
        class="js-stage-item stage-item"
        @click="onStageClick(stage)"
      >
        {{ stage.name }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
