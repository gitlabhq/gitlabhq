<script>
import autoMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/auto_merge';
import Flash from '../../../flash';
import statusIcon from '../mr_widget_status_icon.vue';
import MrWidgetAuthor from '../../components/mr_widget_author.vue';
import eventHub from '../../event_hub';
import { AUTO_MERGE_STRATEGIES } from '../../constants';
import { __ } from '~/locale';

export default {
  name: 'MRWidgetAutoMergeEnabled',
  components: {
    MrWidgetAuthor,
    statusIcon,
  },
  mixins: [autoMergeMixin],
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

      return !shouldRemoveSourceBranch && canRemoveSourceBranch && mergeUserId === currentUserId;
    },
  },
  methods: {
    cancelAutomaticMerge() {
      this.isCancellingAutoMerge = true;
      this.service
        .cancelAutomaticMerge()
        .then(res => res.data)
        .then(data => {
          eventHub.$emit('UpdateWidgetData', data);
        })
        .catch(() => {
          this.isCancellingAutoMerge = false;
          Flash(__('Something went wrong. Please try again.'));
        });
    },
    removeSourceBranch() {
      const options = {
        sha: this.mr.sha,
        auto_merge_strategy: this.mr.autoMergeStrategy,
        should_remove_source_branch: true,
      };

      this.isRemovingSourceBranch = true;
      this.service
        .merge(options)
        .then(res => res.data)
        .then(data => {
          if (AUTO_MERGE_STRATEGIES.includes(data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
          }
        })
        .catch(() => {
          this.isRemovingSourceBranch = false;
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
      <h4 class="d-flex align-items-start">
        <span class="append-right-10">
          <span class="js-status-text-before-author">{{ statusTextBeforeAuthor }}</span>
          <mr-widget-author :author="mr.setToAutoMergeBy" />
          <span class="js-status-text-after-author">{{ statusTextAfterAuthor }}</span>
        </span>
        <a
          v-if="mr.canCancelAutomaticMerge"
          :disabled="isCancellingAutoMerge"
          role="button"
          href="#"
          class="btn btn-sm btn-default js-cancel-auto-merge"
          @click.prevent="cancelAutomaticMerge"
        >
          <i v-if="isCancellingAutoMerge" class="fa fa-spinner fa-spin" aria-hidden="true"> </i>
          {{ cancelButtonText }}
        </a>
      </h4>
      <section class="mr-info-list">
        <p>
          {{ s__('mrWidget|The changes will be merged into') }}
          <a :href="mr.targetBranchPath" class="label-branch">{{ mr.targetBranch }}</a>
        </p>
        <p v-if="mr.shouldRemoveSourceBranch">
          {{ s__('mrWidget|The source branch will be deleted') }}
        </p>
        <p v-else class="d-flex align-items-start">
          <span class="append-right-10">{{
            s__('mrWidget|The source branch will not be deleted')
          }}</span>
          <a
            v-if="canRemoveSourceBranch"
            :disabled="isRemovingSourceBranch"
            role="button"
            class="btn btn-sm btn-default js-remove-source-branch"
            href="#"
            @click.prevent="removeSourceBranch"
          >
            <i v-if="isRemovingSourceBranch" class="fa fa-spinner fa-spin" aria-hidden="true"> </i>
            {{ s__('mrWidget|Delete source branch') }}
          </a>
        </p>
      </section>
    </div>
  </div>
</template>
