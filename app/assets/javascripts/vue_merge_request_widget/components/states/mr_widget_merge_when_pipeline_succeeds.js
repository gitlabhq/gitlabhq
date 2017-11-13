import Flash from '../../../flash';
import statusIcon from '../mr_widget_status_icon';
import MRWidgetAuthor from '../../components/mr_widget_author';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetMergeWhenPipelineSucceeds',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  components: {
    'mr-widget-author': MRWidgetAuthor,
    statusIcon,
  },
  data() {
    return {
      isCancellingAutoMerge: false,
      isRemovingSourceBranch: false,
    };
  },
  computed: {
    canRemoveSourceBranch() {
      const { shouldRemoveSourceBranch, canRemoveSourceBranch,
        mergeUserId, currentUserId } = this.mr;

      return !shouldRemoveSourceBranch && canRemoveSourceBranch && mergeUserId === currentUserId;
    },
  },
  methods: {
    cancelAutomaticMerge() {
      this.isCancellingAutoMerge = true;
      this.service.cancelAutomaticMerge()
        .then(res => res.json())
        .then((res) => {
          eventHub.$emit('UpdateWidgetData', res);
        })
        .catch(() => {
          this.isCancellingAutoMerge = false;
          new Flash('Something went wrong. Please try again.'); // eslint-disable-line
        });
    },
    removeSourceBranch() {
      const options = {
        sha: this.mr.sha,
        merge_when_pipeline_succeeds: true,
        should_remove_source_branch: true,
      };

      this.isRemovingSourceBranch = true;
      this.service.mergeResource.save(options)
        .then(res => res.json())
        .then((res) => {
          if (res.status === 'merge_when_pipeline_succeeds') {
            eventHub.$emit('MRWidgetUpdateRequested');
          }
        })
        .catch(() => {
          this.isRemovingSourceBranch = false;
          new Flash('Something went wrong. Please try again.'); // eslint-disable-line
        });
    },
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="success" />
      <div class="media-body">
        <h4>
          Set by
          <mr-widget-author :author="mr.setToMWPSBy" />
          to be merged automatically when the pipeline succeeds
          <a
            v-if="mr.canCancelAutomaticMerge"
            @click.prevent="cancelAutomaticMerge"
            :disabled="isCancellingAutoMerge"
            role="button"
            href="#"
            class="btn btn-xs btn-default js-cancel-auto-merge">
            <i
              v-if="isCancellingAutoMerge"
              class="fa fa-spinner fa-spin"
              aria-hidden="true" />
              Cancel automatic merge
          </a>
        </h4>
        <section class="mr-info-list">
          <p>The changes will be merged into
            <a
              :href="mr.targetBranchPath"
              class="label-branch">
              {{mr.targetBranch}}
            </a>
          </p>
          <p v-if="mr.shouldRemoveSourceBranch">
            The source branch will be removed
          </p>
          <p v-else>
            The source branch will not be removed
            <a
              v-if="canRemoveSourceBranch"
              :disabled="isRemovingSourceBranch"
              @click.prevent="removeSourceBranch"
              role="button"
              class="btn btn-xs btn-default js-remove-source-branch"
              href="#">
              <i
              v-if="isRemovingSourceBranch"
              class="fa fa-spinner fa-spin"
              aria-hidden="true" />
              Remove source branch
            </a>
          </p>
        </section>
      </div>
    </div>
  `,
};
