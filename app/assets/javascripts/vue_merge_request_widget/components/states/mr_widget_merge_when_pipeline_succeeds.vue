<script>
  import Flash from '../../../flash';
  import statusIcon from '../mr_widget_status_icon.vue';
  import mrWidgetAuthor from '../../components/mr_widget_author.vue';
  import eventHub from '../../event_hub';

  export default {
    name: 'MRWidgetMergeWhenPipelineSucceeds',
    components: {
      mrWidgetAuthor,
      statusIcon,
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
        isCancellingAutoMerge: false,
        isRemovingSourceBranch: false,
      };
    },
    computed: {
      canRemoveSourceBranch() {
        const {
          shouldRemoveSourceBranch,
          canRemoveSourceBranch,
          mergeUserId,
          currentUserId,
        } = this.mr;

        return !shouldRemoveSourceBranch &&
          canRemoveSourceBranch &&
          mergeUserId === currentUserId;
      },
    },
    methods: {
      cancelAutomaticMerge() {
        this.isCancellingAutoMerge = true;
        this.service.cancelAutomaticMerge()
          .then(res => res.data)
          .then((data) => {
            eventHub.$emit('UpdateWidgetData', data);
          })
          .catch(() => {
            this.isCancellingAutoMerge = false;
            Flash('Something went wrong. Please try again.');
          });
      },
      removeSourceBranch() {
        const options = {
          sha: this.mr.sha,
          merge_when_pipeline_succeeds: true,
          should_remove_source_branch: true,
        };

        this.isRemovingSourceBranch = true;
        this.service.merge(options)
          .then(res => res.data)
          .then((data) => {
            if (data.status === 'merge_when_pipeline_succeeds') {
              eventHub.$emit('MRWidgetUpdateRequested');
            }
          })
          .catch(() => {
            this.isRemovingSourceBranch = false;
            Flash('Something went wrong. Please try again.');
          });
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon status="success" />
    <div class="media-body">
      <h4 class="flex-container-block">
        <span class="append-right-10">
          {{ s__("mrWidget|Set by") }}
          <mr-widget-author :author="mr.setToMWPSBy" />
          {{ s__("mrWidget|to be merged automatically when the pipeline succeeds") }}
        </span>
        <a
          v-if="mr.canCancelAutomaticMerge"
          @click.prevent="cancelAutomaticMerge"
          :disabled="isCancellingAutoMerge"
          role="button"
          href="#"
          class="btn btn-xs btn-secondary js-cancel-auto-merge">
          <i
            v-if="isCancellingAutoMerge"
            class="fa fa-spinner fa-spin"
            aria-hidden="true"
          >
          </i>
          {{ s__("mrWidget|Cancel automatic merge") }}
        </a>
      </h4>
      <section class="mr-info-list">
        <p>
          {{ s__("mrWidget|The changes will be merged into") }}
          <a
            :href="mr.targetBranchPath"
            class="label-branch"
          >
            {{ mr.targetBranch }}
          </a>
        </p>
        <p v-if="mr.shouldRemoveSourceBranch">
          {{ s__("mrWidget|The source branch will be removed") }}
        </p>
        <p
          v-else
          class="flex-container-block"
        >
          <span class="append-right-10">
            {{ s__("mrWidget|The source branch will not be removed") }}
          </span>
          <a
            v-if="canRemoveSourceBranch"
            :disabled="isRemovingSourceBranch"
            @click.prevent="removeSourceBranch"
            role="button"
            class="btn btn-xs btn-secondary js-remove-source-branch"
            href="#"
          >
            <i
              v-if="isRemovingSourceBranch"
              class="fa fa-spinner fa-spin"
              aria-hidden="true"
            >
            </i>
            {{ s__("mrWidget|Remove source branch") }}
          </a>
        </p>
      </section>
    </div>
  </div>
</template>
