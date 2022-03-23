<script>
import { GlAlert } from '@gitlab/ui';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { i18n } from '../constants';
import workItemQuery from '../graphql/work_item.query.graphql';
import WorkItemTitle from '../components/work_item_title.vue';

export default {
  i18n,
  components: {
    GlAlert,
    WorkItemTitle,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      workItem: {},
      error: undefined,
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.gid,
        };
      },
      error() {
        this.error = this.$options.i18n.fetchError;
      },
    },
  },
  computed: {
    gid() {
      return convertToGraphQLId(TYPE_WORK_ITEM, this.id);
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">
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
