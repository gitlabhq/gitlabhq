<script>
import { GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import api from '~/api';
import { s__ } from '~/locale';
import { truncateSha } from '~/lib/utils/text_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import modalEventHub from '~/projects/commit/event_hub';
import mergeSourceQuery from '../../queries/states/merge_source.query.graphql';
import sourceBranchRemovalMixin from '../../mixins/source_branch_removal';
import { POST_MERGE_DELETE_BRANCH_EVENT } from '../../constants';
import { MR_WIDGET_DELETE_SOURCE_BRANCH } from '../../i18n';
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetMerged',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlLink,
    GlSprintf,
    MrWidgetAuthorTime,
    StateContainer,
  },
  mixins: [sourceBranchRemovalMixin, glFeatureFlagsMixin()],
  apollo: {
    mergeSource: {
      query: mergeSourceQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetMergeSource;
      },
      variables() {
        return { projectPath: this.mr.targetProjectFullPath, iid: `${this.mr.iid}` };
      },
      update: (data) => data?.project?.mergeRequest?.mergeSource,
    },
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { mergeSource: null };
  },

  computed: {
    sourceMergeRequest() {
      return this.mergeSource?.mergeRequest;
    },
    mergeSourceMessage() {
      if (!this.mergeSource) return null;
      if (this.sourceMergeRequest) return s__('mrWidget|Commits included in %{link}');
      if (this.mergeSource.commitSha) {
        return s__('mrWidget|Commits included in a direct push to %{branch} (%{sha})');
      }

      return s__("mrWidget|Commits included in a merge request that you don't have access to");
    },
    shortSourceCommitSha() {
      return this.mergeSource?.commitSha && truncateSha(this.mergeSource.commitSha);
    },
    revertTitle() {
      return s__('mrWidget|Revert this merge request in a new merge request');
    },
    cherryPickTitle() {
      return s__('mrWidget|Cherry-pick this merge request in a new merge request');
    },
    revertLabel() {
      return s__('mrWidget|Revert');
    },
    cherryPickLabel() {
      return s__('mrWidget|Cherry-pick');
    },
    actions() {
      const actionsList = [];

      if (this.mr.revertInForkPath) {
        actionsList.push({
          text: this.revertLabel,
          tooltipText: this.revertTitle,
          href: this.mr.revertInForkPath,
          testId: 'revert-button',
          dataMethod: 'post',
        });
      } else {
        actionsList.push({
          text: this.revertLabel,
          tooltipText: this.revertTitle,
          testId: 'revert-button',
          onClick: () => this.openRevertModal(),
        });
      }

      if (this.mr.canCherryPickInCurrentMR) {
        actionsList.push({
          text: this.cherryPickLabel,
          tooltipText: this.cherryPickTitle,
          testId: 'cherry-pick-button',
          onClick: () => this.openCherryPickModal(),
        });
      } else if (this.mr.cherryPickInForkPath) {
        actionsList.push({
          text: this.cherryPickLabel,
          tooltipText: this.cherryPickTitle,
          href: this.mr.cherryPickInForkPath,
          testId: 'cherry-pick-button',
          dataMethod: 'post',
        });
      }

      if (this.shouldShowRemoveSourceBranch) {
        actionsList.push({
          text: MR_WIDGET_DELETE_SOURCE_BRANCH,
          class: 'js-remove-branch-button',
          onClick: () => this.removeSourceBranch(POST_MERGE_DELETE_BRANCH_EVENT),
        });
      }

      return actionsList;
    },
  },
  mounted() {
    document.dispatchEvent(new CustomEvent('merged:UpdateActions'));
  },
  methods: {
    openRevertModal() {
      api.trackRedisHllUserEvent('i_code_review_post_merge_click_revert');

      modalEventHub.$emit(OPEN_REVERT_MODAL);
    },
    openCherryPickModal() {
      api.trackRedisHllUserEvent('i_code_review_post_merge_click_cherry_pick');

      modalEventHub.$emit(OPEN_CHERRY_PICK_MODAL);
    },
  },
};
</script>
<template>
  <state-container :actions="actions" status="merged">
    <div class="gl-flex gl-grow gl-flex-col">
      <mr-widget-author-time
        :action-text="s__('mrWidget|Merged by')"
        :author="mr.metrics.mergedBy"
        :date-title="mr.metrics.mergedAt"
        :date-readable="mr.metrics.readableMergedAt"
      />
      <p v-if="mergeSourceMessage" class="gl-mb-0 gl-text-subtle" data-testid="merge-source">
        <gl-sprintf :message="mergeSourceMessage">
          <template #link>
            <gl-link :href="sourceMergeRequest.webPath">{{ sourceMergeRequest.reference }}</gl-link>
          </template>
          <template #branch>
            <code>{{ mr.targetBranch }}</code>
          </template>
          <template #sha>
            <code>{{ shortSourceCommitSha }}</code>
          </template>
        </gl-sprintf>
      </p>
    </div>
  </state-container>
</template>
