<script>
import { GlLink, GlDisclosureDropdown, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { Mousetrap } from '~/lib/mousetrap';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { clickCopyToClipboardButton } from '~/behaviors/copy_to_clipboard';
import { keysFor, MR_COPY_SOURCE_BRANCH_NAME } from '~/behaviors/shortcuts/keybindings';

export default {
  components: {
    ClipboardButton,
    GlDisclosureDropdown,
    GlLink,
    GlSprintf,
    CiIcon,
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
    dropdownItems() {
      return this.stages.map((stage) => ({
        text: stage.name,
        action: () => {
          this.onStageClick(stage);
        },
      }));
    },

    hasRef() {
      return !isEmpty(this.pipeline.ref);
    },
    isTriggeredByMergeRequest() {
      return Boolean(this.pipeline.merge_request);
    },
    isMergeRequestPipeline() {
      return Boolean(this.pipeline.flags && this.pipeline.flags.merge_request_pipeline);
    },
    pipelineInfo() {
      if (!this.hasRef) {
        return s__('Job|%{boldStart}Pipeline%{boldEnd} %{id} %{status}');
      }
      if (!this.isTriggeredByMergeRequest) {
        return s__('Job|%{boldStart}Pipeline%{boldEnd} %{id} %{status} for %{ref}');
      }
      if (!this.isMergeRequestPipeline) {
        return s__('Job|%{boldStart}Pipeline%{boldEnd} %{id} %{status} for %{mrId} with %{source}');
      }

      return s__(
        'Job|%{boldStart}Pipeline%{boldEnd} %{id} for %{mrId} with %{source} into %{target}',
      );
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(MR_COPY_SOURCE_BRANCH_NAME), this.handleKeyboardCopy);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(MR_COPY_SOURCE_BRANCH_NAME));
  },
  methods: {
    onStageClick(stage) {
      this.$emit('requestSidebarStageDropdown', stage);
    },
    handleKeyboardCopy() {
      let button;

      if (!this.hasRef) {
        return;
      }
      if (!this.isTriggeredByMergeRequest) {
        button = this.$refs['copy-source-ref-link'];
      } else {
        button = this.$refs['copy-source-branch-link'];
      }

      clickCopyToClipboardButton(button.$el);
    },
  },
};
</script>
<template>
  <div class="dropdown">
    <div class="js-pipeline-info gl-block" data-testid="pipeline-info">
      <gl-sprintf :message="pipelineInfo">
        <template #bold="{ content }">
          <span class="gl-inline-flex gl-font-bold">{{ content }}</span>
        </template>
        <template #id>
          <gl-link
            :href="pipeline.path"
            class="js-pipeline-path link-commit !gl-text-link"
            data-testid="pipeline-path"
            >#{{ pipeline.id }}</gl-link
          >
        </template>
        <template #status>
          <ci-icon
            :status="pipeline.details.status"
            show-status-text
            data-testid="pipeline-status-link"
          />
        </template>
        <template #mrId>
          <gl-link
            :href="pipeline.merge_request.path"
            class="link-commit !gl-text-link"
            data-testid="mr-link"
            >!{{ pipeline.merge_request.iid }}</gl-link
          >
        </template>
        <template #ref>
          <gl-link
            :href="pipeline.ref.path"
            class="link-commit ref-name gl-break-all"
            data-testid="source-ref-link"
            >{{ pipeline.ref.name }}</gl-link
          ><clipboard-button
            ref="copy-source-ref-link"
            :text="pipeline.ref.name"
            :title="__('Copy reference')"
            category="tertiary"
            size="small"
            data-testid="copy-source-ref-link"
          />
        </template>
        <template #source>
          <gl-link
            :href="pipeline.merge_request.source_branch_path"
            class="link-commit ref-name gl-mt-1 gl-break-all"
            data-testid="source-branch-link"
            >{{ pipeline.merge_request.source_branch }}</gl-link
          ><clipboard-button
            ref="copy-source-branch-link"
            :text="pipeline.merge_request.source_branch"
            :title="__('Copy branch name')"
            category="tertiary"
            size="small"
            data-testid="copy-source-branch-link"
          />
        </template>
        <template #target>
          <gl-link
            :href="pipeline.merge_request.target_branch_path"
            class="link-commit ref-name gl-mt-1"
            data-testid="target-branch-link"
            >{{ pipeline.merge_request.target_branch }}</gl-link
          ><clipboard-button
            :text="pipeline.merge_request.target_branch"
            :title="__('Copy branch name')"
            category="tertiary"
            size="small"
            data-testid="copy-target-branch-link"
          />
        </template>
      </gl-sprintf>
    </div>

    <gl-disclosure-dropdown
      :toggle-text="selectedStage"
      :items="dropdownItems"
      block
      class="gl-mt-2"
    />
  </div>
</template>
