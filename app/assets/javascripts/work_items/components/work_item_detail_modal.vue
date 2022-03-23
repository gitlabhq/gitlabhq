<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { i18n } from '../constants';
import workItemQuery from '../graphql/work_item.query.graphql';
import WorkItemTitle from './work_item_title.vue';

export default {
  i18n,
  components: {
    GlAlert,
    GlModal,
    WorkItemTitle,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
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
  <gl-modal hide-footer modal-id="work-item-detail-modal" :visible="visible" @hide="$emit('close')">
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
  </gl-modal>
</template>
