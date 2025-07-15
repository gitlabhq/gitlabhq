<script>
import { GlAlert } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import ZenMode from '~/zen_mode';
import WorkItemDetail from '../components/work_item_detail.vue';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_DELETING,
  NAME_TO_TEXT_LOWERCASE_MAP,
  WORK_ITEM_TYPE_NAME_EPIC,
} from '../constants';
import deleteWorkItemMutation from '../graphql/delete_work_item.mutation.graphql';

export default {
  components: {
    GlAlert,
    WorkItemDetail,
  },
  inject: { issuesListPath: 'issuesListPath', epicsListPath: { default: '' } },
  props: {
    iid: {
      type: String,
      required: true,
    },
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: '',
    };
  },
  mounted() {
    this.ZenMode = new ZenMode();
  },
  methods: {
    deleteWorkItem({ workItemType, workItemId: id }) {
      this.$apollo
        .mutate({
          mutation: deleteWorkItemMutation,
          variables: {
            input: { id },
          },
        })
        .then(({ data: { workItemDelete, errors } }) => {
          if (errors?.length) {
            throw new Error(errors[0].message);
          }

          if (workItemDelete?.errors.length) {
            throw new Error(workItemDelete.errors[0]);
          }

          const msg = sprintfWorkItem(s__('WorkItem|%{workItemType} deleted'), workItemType);
          this.$toast.show(msg);
          visitUrl(
            workItemType === WORK_ITEM_TYPE_NAME_EPIC ? this.epicsListPath : this.issuesListPath,
          );
        })
        .catch((e) => {
          this.error =
            e.message ||
            sprintf(I18N_WORK_ITEM_ERROR_DELETING, {
              workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.workItemType],
            });
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">{{ error }}</gl-alert>
    <work-item-detail
      :new-comment-template-paths="newCommentTemplatePaths"
      :work-item-full-path="rootPageFullPath"
      :work-item-iid="iid"
      @deleteWorkItem="deleteWorkItem($event)"
    />
  </div>
</template>
