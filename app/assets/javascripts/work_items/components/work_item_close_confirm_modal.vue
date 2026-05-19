<script>
import { GlModal, GlLink } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

export default {
  name: 'WorkItemCloseConfirmModal',
  components: { GlModal, GlLink },
  props: {
    workItemType: {
      type: String,
      required: true,
    },
    isBlockedByOpenItems: {
      type: Boolean,
      required: true,
    },
    blockerItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    visible: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['hide', 'proceed'],
  computed: {
    title() {
      if (this.isBlockedByOpenItems) {
        return sprintf(
          s__('WorkItem|Are you sure you want to close this blocked %{workItemType}?'),
          { workItemType: this.workItemType },
        );
      }
      return sprintf(s__('WorkItem|Are you sure you want to close this %{workItemType}?'), {
        workItemType: this.workItemType,
      });
    },
    body() {
      if (this.isBlockedByOpenItems) {
        return sprintf(
          s__('WorkItem|This %{workItemType} is currently blocked by the following items:'),
          { workItemType: this.workItemType },
        );
      }
      return sprintf(
        s__(
          'WorkItem|This %{workItemType} has open child items. If you close this %{workItemType}, they will remain open.',
        ),
        { workItemType: this.workItemType },
      );
    },
    actionPrimary() {
      return {
        text: sprintf(s__('WorkItem|Yes, close %{workItemType}'), {
          workItemType: this.workItemType,
        }),
      };
    },
    actionCancel() {
      return { text: __('Cancel') };
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="work-item-close-confirm-modal"
    data-testid="work-item-close-confirm-modal"
    :visible="visible"
    :action-cancel="actionCancel"
    :action-primary="actionPrimary"
    :title="title"
    @hide="$emit('hide')"
    @primary="$emit('proceed')"
  >
    <p>{{ body }}</p>
    <ul v-if="isBlockedByOpenItems">
      <li v-for="issue in blockerItems" :key="issue.workItem.iid">
        <!-- eslint-disable-next-line local-rules/vue-no-web-url -->
        <gl-link :href="issue.workItem.webUrl">#{{ issue.workItem.iid }}</gl-link>
      </li>
    </ul>
  </gl-modal>
</template>
