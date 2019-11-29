<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import Flash from '~/flash';
import tooltip from '~/vue_shared/directives/tooltip';
import { s__, __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import MrWidgetAuthorTime from '../../components/mr_widget_author_time.vue';
import statusIcon from '../mr_widget_status_icon.vue';
import eventHub from '../../event_hub';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'MRWidgetMerged',
  directives: {
    tooltip,
  },
  components: {
    MrWidgetAuthorTime,
    statusIcon,
    ClipboardButton,
    GlLoadingIcon,
  },
  props: {
    mr: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    service: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  computed: {
    shouldShowRemoveSourceBranch() {
      const { sourceBranchRemoved, isRemovingSourceBranch, canRemoveSourceBranch } = this.mr;

      return (
        !sourceBranchRemoved &&
        canRemoveSourceBranch &&
        !this.isMakingRequest &&
        !isRemovingSourceBranch
      );
    },
    shouldShowSourceBranchRemoving() {
      const { sourceBranchRemoved, isRemovingSourceBranch } = this.mr;
      return !sourceBranchRemoved && (isRemovingSourceBranch || this.isMakingRequest);
    },
    shouldShowMergedButtons() {
      const {
        canRevertInCurrentMR,
        canCherryPickInCurrentMR,
        revertInForkPath,
        cherryPickInForkPath,
      } = this.mr;

      return (
        canRevertInCurrentMR || canCherryPickInCurrentMR || revertInForkPath || cherryPickInForkPath
      );
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
  },
  methods: {
    removeSourceBranch() {
      this.isMakingRequest = true;

      this.service
        .removeSourceBranch()
        .then(res => res.data)
        .then(data => {
          // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
          // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
          if (data.message === 'Branch was deleted') {
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              this.isMakingRequest = false;
            });
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          Flash(__('Something went wrong. Please try again.'));
        });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon status="success" />
    <div class="media-body">
      <div class="space-children">
        <mr-widget-author-time
          :action-text="s__('mrWidget|Merged by')"
          :author="mr.metrics.mergedBy"
          :date-title="mr.metrics.mergedAt"
          :date-readable="mr.metrics.readableMergedAt"
        />
        <a
          v-if="mr.canRevertInCurrentMR"
          v-tooltip
          :title="revertTitle"
          class="btn btn-close btn-sm"
          href="#modal-revert-commit"
          data-toggle="modal"
          data-container="body"
        >
          {{ revertLabel }}
        </a>
        <a
          v-else-if="mr.revertInForkPath"
          v-tooltip
          :href="mr.revertInForkPath"
          :title="revertTitle"
          class="btn btn-close btn-sm"
          data-method="post"
        >
          {{ revertLabel }}
        </a>
        <a
          v-if="mr.canCherryPickInCurrentMR"
          v-tooltip
          :title="cherryPickTitle"
          class="btn btn-default btn-sm"
          href="#modal-cherry-pick-commit"
          data-toggle="modal"
          data-container="body"
        >
          {{ cherryPickLabel }}
        </a>
        <a
          v-else-if="mr.cherryPickInForkPath"
          v-tooltip
          :href="mr.cherryPickInForkPath"
          :title="cherryPickTitle"
          class="btn btn-default btn-sm"
          data-method="post"
        >
          {{ cherryPickLabel }}
        </a>
      </div>
      <section class="mr-info-list" data-qa-selector="merged_status_content">
        <p>
          {{ s__('mrWidget|The changes were merged into') }}
          <span class="label-branch">
            <a :href="mr.targetBranchPath">{{ mr.targetBranch }}</a>
          </span>
          <template v-if="mr.mergeCommitSha">
            with
            <a
              :href="mr.mergeCommitPath"
              class="commit-sha js-mr-merged-commit-sha"
              v-text="mr.shortMergeCommitSha"
            >
            </a>
            <clipboard-button
              :title="__('Copy commit SHA')"
              :text="mr.mergeCommitSha"
              css-class="btn-default btn-transparent btn-clipboard js-mr-merged-copy-sha"
            />
          </template>
        </p>
        <p v-if="mr.sourceBranchRemoved">
          {{ s__('mrWidget|The source branch has been deleted') }}
        </p>
        <p v-if="shouldShowRemoveSourceBranch" class="space-children">
          <span>{{ s__('mrWidget|You can delete the source branch now') }}</span>
          <button
            :disabled="isMakingRequest"
            type="button"
            class="btn btn-sm btn-default js-remove-branch-button"
            @click="removeSourceBranch"
          >
            {{ s__('mrWidget|Delete source branch') }}
          </button>
        </p>
        <p v-if="shouldShowSourceBranchRemoving">
          <gl-loading-icon :inline="true" />
          <span> {{ s__('mrWidget|The source branch is being deleted') }} </span>
        </p>
      </section>
    </div>
  </div>
</template>
