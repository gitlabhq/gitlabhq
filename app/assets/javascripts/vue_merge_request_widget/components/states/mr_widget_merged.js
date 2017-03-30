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
      isRemovingSourceBranch: false,
    };
  },
  computed: {
    shouldShowRemoveSourceBranch() {
      return this.mr.canRemoveSourceBranch && !this.isRemovingSourceBranch;
    },
  },
  methods: {
    removeSourceBranch() {
      this.isRemovingSourceBranch = true;
      // TODO: Error handling
      this.service.removeSourceBranch()
        .then(res => res.json())
        .then((res) => {
          if (res.message === 'Branch was removed') {
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              this.isRemovingSourceBranch = false;
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
          <a :href="mr.targetBranchPath" class="label-branch">
            {{mr.targetBranch}}
          </a>
        </p>
        <p v-if="mr.sourceBranchRemoved">The source branch has been removed.</p>
        <p v-if="shouldShowRemoveSourceBranch">
          You can remove source branch now.
          <button
            @click="removeSourceBranch"
            :class="{ disabled: isRemovingSourceBranch }"
            type="button" class="btn btn-xs btn-default">Remove Source Branch</button>
        </p>
        <p v-if="isRemovingSourceBranch">
          The source branch is being removed.
          <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
        </p>
      </section>
      <div class="merged-buttons clearfix">
        <a
          v-if="mr.canRevert"
          class="btn btn-close btn-sm has-tooltip"
          href="#modal-revert-commit"
          data-toggle="modal"
          data-container="body"
          data-original-title="Revert this merge request in a new merge request">Revert</a>
        <a
          v-if="mr.canBeCherryPicked"
          class="btn btn-default btn-sm has-tooltip"
          href="#modal-cherry-pick-commit"
          data-toggle="modal"
          data-container="body"
          data-original-title="Cherry-pick this merge request in a new merge request">Cherry-pick</a>
      </div>
    </div>
  `,
};
