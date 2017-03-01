import mrWidgetAuthorTime from '../../components/mr_widget_author_time';

export default {
  name: 'MRWidgetMerged',
  props: {
    mr: { type: Object, required: true, default: () => ({}) },
  },
  components: {
    'mr-widget-author-and-time': mrWidgetAuthorTime,
  },
  data() {
    return {
      isSourceBranchRemoving: false,
    };
  },
  methods: {
    removeSourceBranch() {
      this.isSourceBranchRemoving = true;
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
      <section>
        <p>The changes were merged into
          <a :href="mr.targetBranchPath" class="label-branch">
            {{mr.targetBranch}}
          </a>
        </p>
        <p v-if="mr.sourceBranchRemoved">The source branch has been removed.</p>
        <p v-if="mr.canRemoveSourceBranch">
          You can remove source branch now.
          <a
            :href="mr.sourceBranchPath"
            :class="{ disabled: isSourceBranchRemoving }"
            @click="removeSourceBranch"
            class="btn btn-default remove_source_branch"
            data-remote="true" data-method="delete">Remove Source Branch</a>
        </p>
        <p v-if="isSourceBranchRemoving">
          The source branch is being removed.
          <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
        </p>
      </section>
      <div class="merged-buttons clearfix">
        <a
          v-if="mr.canRevert"
          class="btn btn-warning has-tooltip"
          href="#modal-revert-commit"
          data-toggle="modal"
          data-container="body"
          data-original-title="Revert this merge request in a new merge request">Revert</a>
        <a
          v-if="mr.canBeCherryPicked"
          class="btn btn-default has-tooltip"
          href="#modal-cherry-pick-commit"
          data-toggle="modal"
          data-container="body"
          data-original-title="Cherry-pick this merge request in a new merge request">Cherry-pick</a>
      </div>
    </div>
  `,
};
