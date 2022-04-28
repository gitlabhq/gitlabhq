<script>
import { GlAlert } from '@gitlab/ui';
import { i18n } from '../constants';
import workItemQuery from '../graphql/work_item.query.graphql';
import workItemTitleSubscription from '../graphql/work_item_title.subscription.graphql';
import WorkItemActions from './work_item_actions.vue';
import WorkItemState from './work_item_state.vue';
import WorkItemTitle from './work_item_title.vue';

export default {
  i18n,
  components: {
    GlAlert,
    WorkItemActions,
    WorkItemTitle,
    WorkItemState,
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      error: undefined,
      workItem: {},
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId;
      },
      error() {
        this.error = this.$options.i18n.fetchError;
      },
      subscribeToMore: {
        document: workItemTitleSubscription,
        variables() {
          return {
            issuableId: this.workItemId,
          };
        },
      },
    },
  },
  computed: {
    workItemLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    canDelete() {
      return this.workItem?.userPermissions?.deleteWorkItem;
    },
  },
  methods: {
    handleWorkItemDeleted() {
      this.$emit('workItemDeleted');
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
      {{ error }}
    </gl-alert>

    <div class="gl-display-flex">
      <work-item-title
        :loading="workItemLoading"
        :work-item-id="workItem.id"
        :work-item-title="workItem.title"
        :work-item-type="workItemType"
        class="gl-mr-5"
        @error="error = $event"
      />
      <work-item-actions
        :work-item-id="workItem.id"
        :can-delete="canDelete"
        class="gl-ml-auto gl-mt-5"
        @workItemDeleted="handleWorkItemDeleted"
        @error="error = $event"
      />
    </div>
    <work-item-state :loading="workItemLoading" :work-item="workItem" @error="error = $event" />
  </section>
</template>
