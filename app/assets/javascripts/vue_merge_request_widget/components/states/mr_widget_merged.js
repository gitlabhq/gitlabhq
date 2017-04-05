import mrWidgetAuthorTime from '../../components/mr_widget_author_time';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetMerged',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  components: {
    'mr-widget-author-and-time': mrWidgetAuthorTime,
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
    shouldShowRevertForCurrentMR() {
      return this.mr.canBeReverted && this.mr.userCanCollaborateWithProject;
    },
    // TODO: Remove UJS
    shouldShowRevertForForkMR() {
      return this.mr.canBeReverted && this.mr.userCanForkProject;
    },
    shouldShowCherryPickForCurrentMR() {
      return this.mr.canBeCherryPicked && this.mr.userCanCollaborateWithProject;
    },
    // TODO: Remove UJS
    shouldShowCherryPickForForkMR() {
      return this.mr.canBeCherryPicked && this.mr.userCanForkProject;
    },
  },
  methods: {
    removeSourceBranch() {
      this.isMakingRequest = true;
      // TODO: Error handling
      this.service.removeSourceBranch()
        .then(res => res.json())
        .then((res) => {
          if (res.message === 'Branch was removed') {
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              this.isMakingRequest = false;
            });
          }
        });
    },
  },
  template: `
    <div class="mr-widget-body">
      <mr-widget-author-and-time
        actionText="Merged by"
        :author="mr.mergedBy"
        :dateTitle="mr.updatedAt"
        :dateReadable="mr.mergedAt"
      />
      <section class="mr-info-list">
        <div class="legend"></div>
        <p>
          The changes were merged into
          <span class="label-branch">
            <a :href="mr.targetBranchPath">{{mr.targetBranch}}</a>
          </span>
        </p>
        <p v-if="mr.sourceBranchRemoved">The source branch has been removed.</p>
        <p v-if="shouldShowRemoveSourceBranch">
          You can remove source branch now.
          <button
            @click="removeSourceBranch"
            :class="{ disabled: isMakingRequest }"
            type="button" class="btn btn-xs btn-default">Remove Source Branch</button>
        </p>
        <p v-if="shouldShowSourceBranchRemoving">
          The source branch is being removed.
          <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
        </p>
      </section>
      <div class="merged-buttons clearfix">
        <a
          v-if="shouldShowRevertForCurrentMR"
          class="btn btn-close btn-sm has-tooltip"
          href="#modal-revert-commit"
          data-toggle="modal"
          data-container="body"
          data-original-title="Revert this merge request in a new merge request">Revert</a>
        <a
          v-else-if="shouldShowRevertForForkMR"
          class="btn btn-close btn-sm has-tooltip"
          data-method='post'
          :href="mr.revertInForkPath"
          data-original-title="Revert this merge request in a new merge request">Revert</a>
        <a
          v-if="shouldShowCherryPickForCurrentMR"
          class="btn btn-default btn-sm has-tooltip"
          href="#modal-cherry-pick-commit"
          data-toggle="modal"
          data-container="body"
          data-original-title="Cherry-pick this merge request in a new merge request">Cherry-pick</a>
        <a
          v-else-if="shouldShowCherryPickForForkMR"
          class="btn btn-default btn-sm has-tooltip"
          data-method='post'
          :href="mr.cherryPickInForkPath"
          data-original-title="Cherry-pick this merge request in a new merge request">Cherry-pick</a>
      </div>
    </div>
  `,
};
