<script>
import { GlAlert } from '@gitlab/ui';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import ZenMode from '~/zen_mode';
import WorkItemDetail from '../components/work_item_detail.vue';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_DELETING,
  I18N_WORK_ITEM_DELETED,
} from '../constants';
import deleteWorkItemMutation from '../graphql/delete_work_item.mutation.graphql';

export default {
  components: {
    GlAlert,
    WorkItemDetail,
  },
  inject: ['issuesListPath'],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: '',
    };
  },
  computed: {
    gid() {
      return convertToGraphQLId(TYPENAME_WORK_ITEM, this.id);
    },
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

          const msg = sprintfWorkItem(I18N_WORK_ITEM_DELETED, workItemType);
          this.$toast.show(msg);
          visitUrl(this.issuesListPath);
        })
        .catch((e) => {
          this.error = e.message || sprintfWorkItem(I18N_WORK_ITEM_ERROR_DELETING, workItemType);
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">{{ error }}</gl-alert>
    <work-item-detail
      :work-item-id="gid"
      :work-item-iid="id"
      @deleteWorkItem="deleteWorkItem($event)"
    />
  </div>
</template>
