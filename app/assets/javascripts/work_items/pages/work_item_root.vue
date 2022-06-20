<script>
import { GlAlert } from '@gitlab/ui';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import ZenMode from '~/zen_mode';
import WorkItemDetail from '../components/work_item_detail.vue';
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
      return convertToGraphQLId(TYPE_WORK_ITEM, this.id);
    },
  },
  mounted() {
    this.ZenMode = new ZenMode();
  },
  methods: {
    deleteWorkItem() {
      this.$apollo
        .mutate({
          mutation: deleteWorkItemMutation,
          variables: {
            input: {
              id: this.gid,
            },
          },
        })
        .then(({ data: { workItemDelete, errors } }) => {
          if (errors?.length) {
            throw new Error(errors[0].message);
          }

          if (workItemDelete?.errors.length) {
            throw new Error(workItemDelete.errors[0]);
          }

          this.$toast.show(s__('WorkItem|Work item deleted'));
          visitUrl(this.issuesListPath);
        })
        .catch((e) => {
          this.error =
            e.message ||
            s__('WorkItem|Something went wrong when deleting the work item. Please try again.');
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">{{ error }}</gl-alert>
    <work-item-detail :work-item-id="gid" @deleteWorkItem="deleteWorkItem" />
  </div>
</template>
