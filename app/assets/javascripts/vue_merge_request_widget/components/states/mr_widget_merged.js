/* global Flash */

import mrWidgetAuthorTime from '../../components/mr_widget_author_time';
import statusIcon from '../mr_widget_status_icon';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetMerged',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  components: {
    'mr-widget-author-and-time': mrWidgetAuthorTime,
    statusIcon,
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  computed: {
    shouldShowRemoveSourceBranch() {
      const { sourceBranchRemoved, isRemovingSourceBranch, canRemoveSourceBranch } = this.mr;

      return !sourceBranchRemoved && canRemoveSourceBranch &&
        !this.isMakingRequest && !isRemovingSourceBranch;
    },
    shouldShowSourceBranchRemoving() {
      const { sourceBranchRemoved, isRemovingSourceBranch } = this.mr;
      return !sourceBranchRemoved && (isRemovingSourceBranch || this.isMakingRequest);
    },
    shouldShowMergedButtons() {
      const { canRevertInCurrentMR, canCherryPickInCurrentMR, revertInForkPath,
        cherryPickInForkPath } = this.mr;

      return canRevertInCurrentMR || canCherryPickInCurrentMR ||
        revertInForkPath || cherryPickInForkPath;
    },
  },
  methods: {
    removeSourceBranch() {
      this.isMakingRequest = true;
      this.service.removeSourceBranch()
        .then(res => res.json())
        .then((res) => {
          if (res.message === 'Branch was removed') {
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              this.isMakingRequest = false;
            });
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          new Flash('Something went wrong. Please try again.'); // eslint-disable-line
        });
    },
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="success" />
      <div class="media-body">
        <div class="space-children">
          <mr-widget-author-and-time
            actionText="Merged by"
            :author="mr.mergedBy"
            :dateTitle="mr.updatedAt"
            :dateReadable="mr.mergedAt" />
          <a
            v-if="mr.canRevertInCurrentMR"
            class="btn btn-close btn-xs has-tooltip"
            href="#modal-revert-commit"
            data-toggle="modal"
            data-container="body"
            title="Revert this merge request in a new merge request">
            Revert
          </a>
          <a
            v-else-if="mr.revertInForkPath"
            class="btn btn-close btn-xs has-tooltip"
            data-method="post"
            :href="mr.revertInForkPath"
            title="Revert this merge request in a new merge request">
            Revert
          </a>
          <a
            v-if="mr.canCherryPickInCurrentMR"
            class="btn btn-default btn-xs has-tooltip"
            href="#modal-cherry-pick-commit"
            data-toggle="modal"
            data-container="body"
            title="Cherry-pick this merge request in a new merge request">
            Cherry-pick
          </a>
          <a
            v-else-if="mr.cherryPickInForkPath"
            class="btn btn-default btn-xs has-tooltip"
            data-method="post"
            :href="mr.cherryPickInForkPath"
            title="Cherry-pick this merge request in a new merge request">
            Cherry-pick
          </a>
        </div>
        <section class="mr-info-list">
          <p>
            The changes were merged into
            <span class="label-branch">
              <a :href="mr.targetBranchPath">{{mr.targetBranch}}</a>
            </span>
          </p>
          <p v-if="mr.sourceBranchRemoved">The source branch has been removed</p>
          <p v-if="shouldShowRemoveSourceBranch" class="space-children">
            <span>You can remove source branch now</span>
            <button
              @click="removeSourceBranch"
              :class="{ disabled: isMakingRequest }"
              type="button"
              class="btn btn-xs btn-default js-remove-branch-button">
              Remove Source Branch
            </button>
          </p>
          <p v-if="shouldShowSourceBranchRemoving">
            <status-icon status="loading" />
            <span>The source branch is being removed</span>
          </p>
        </section>
      </div>
    </div>
  `,
};
