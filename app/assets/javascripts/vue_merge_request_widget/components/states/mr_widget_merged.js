module.exports = {
  name: 'MRWidgetMerged',
  props: {
    mr: { type: Object, required: true, default: () => ({}) }
  },
  template: `
    <div class="mr-widget-body">
      <h4>
        Merged by
        <a class="author_link" :href="mr.mergedBy.webUrl">
          <img :src="mr.mergedBy.avatarUrl" width="16" class="avatar avatar-inline s16" />
          <span class="author">{{mr.mergedBy.name}}</span>
        </a>
        <time :data-original-title='mr.updatedAt' data-toggle="tooltip" data-placement="top" data-container="body">
          {{mr.mergedAt}}
        </time>
      </h4>
      <section>
        <p>The changes were merged into
          <a :href="mr.targetBranchPath" class="label-branch">
            {{mr.targetBranch}}
          </a>
        </p>
        <p v-if="mr.sourceBranchRemoved">The source branch has been removed.</p>
        <p v-if="mr.canRemoveSourceBranch">
          You can remove source branch now.
          <a class="btn btn-default remove_source_branch">Remove Source Branch</a>
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
  `
};
