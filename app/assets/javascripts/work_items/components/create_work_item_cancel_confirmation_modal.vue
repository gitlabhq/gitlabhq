<script>
import { GlButton, GlModal } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlButton,
    GlModal,
  },
  props: {
    isVisible: {
      type: Boolean,
      required: true,
      default: false,
    },
    workItemTypeName: {
      type: String,
      required: true,
      default: s__('Work Item|Epic'),
    },
  },
  computed: {
    cancelConfirmationText() {
      return sprintf(
        s__('WorkItem|Are you sure you want to cancel creating this %{workItemType}?'),
        {
          workItemType: this.workItemTypeName?.toLocaleLowerCase(),
        },
      );
    },
  },
  methods: {
    handleCancelConfirmationAction(decision) {
      if (decision === 'continueEditing') {
        this.$emit('continueEditing');
      } else {
        this.$emit('discardDraft');
      }
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="create-work-item-cancel-confirmation-modal"
    :aria-label="__('Confirmation')"
    :visible="isVisible"
    :scrollable="false"
    no-close-on-esc
    no-close-on-backdrop
    hide-header
    hide-header-close
  >
    <p class="gl-mb-0 gl-mt-4">{{ cancelConfirmationText }}</p>

    <template #modal-footer>
      <gl-button
        type="button"
        data-testid="create-work-item-continue-editing"
        @click="handleCancelConfirmationAction('continueEditing')"
        >{{ s__('WorkItem|Continue editing') }}</gl-button
      >
      <gl-button
        type="button"
        variant="confirm"
        data-testid="create-work-item-discard"
        @click="handleCancelConfirmationAction('discard')"
        >{{ s__('WorkItem|Discard changes') }}</gl-button
      >
    </template>
  </gl-modal>
</template>
