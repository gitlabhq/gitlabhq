<script>
import { GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import workItemQuery from '../graphql/work_item.query.graphql';
import ItemTitle from './item_title.vue';

export default {
  components: {
    GlModal,
    ItemTitle,
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
      update(data) {
        return data.localWorkItem;
      },
      error() {
        this.$emit(
          'error',
          s__('WorkItem|Something went wrong when fetching the work item. Please try again.'),
        );
      },
    },
  },
  computed: {
    workItemTitle() {
      return this.workItem?.widgets?.nodes.find(
        // eslint-disable-next-line no-underscore-dangle
        (widget) => widget.__typename === 'LocalTitleWidget',
      )?.contentText;
    },
  },
};
</script>

<template>
  <gl-modal hide-footer modal-id="work-item-detail-modal" :visible="visible" @hide="$emit('close')">
    <item-title class="gl-m-0!" :initial-title="workItemTitle" />
  </gl-modal>
</template>
