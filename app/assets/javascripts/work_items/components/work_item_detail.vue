<script>
import { GlAlert } from '@gitlab/ui';
import { i18n } from '../constants';
import workItemQuery from '../graphql/work_item.query.graphql';
import workItemTitleSubscription from '../graphql/work_item_title.subscription.graphql';
import WorkItemState from './work_item_state.vue';
import WorkItemTitle from './work_item_title.vue';

export default {
  i18n,
  components: {
    GlAlert,
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
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
      {{ error }}
    </gl-alert>

    <work-item-title
      :loading="workItemLoading"
      :work-item-id="workItem.id"
      :work-item-title="workItem.title"
      :work-item-type="workItemType"
      @error="error = $event"
    />
    <work-item-state :loading="workItemLoading" :work-item="workItem" @error="error = $event" />
  </section>
</template>
