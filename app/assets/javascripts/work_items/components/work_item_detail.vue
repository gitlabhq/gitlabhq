<script>
import { GlAlert } from '@gitlab/ui';
import { i18n } from '../constants';
import workItemQuery from '../graphql/work_item.query.graphql';
import workItemTitleSubscription from '../graphql/work_item_title.subscription.graphql';
import WorkItemTitle from './work_item_title.vue';

export default {
  i18n,
  components: {
    GlAlert,
    WorkItemTitle,
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
      :loading="$apollo.queries.workItem.loading"
      :work-item-id="workItem.id"
      :work-item-title="workItem.title"
      :work-item-type="workItemType"
      @error="error = $event"
    />
  </section>
</template>
