<script>
import { GlModal, GlBadge, GlSprintf } from '@gitlab/ui';
import { __, sprintf, n__, s__ } from '~/locale';

export default {
  components: {
    GlModal,
    GlBadge,
    GlSprintf,
  },
  props: {
    refToUntrack: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    modalTitle() {
      if (!this.refToUntrack) return '';

      const refType =
        this.refToUntrack.refType === 'TAG'
          ? s__('SecurityTrackedRefs|tag')
          : s__('SecurityTrackedRefs|branch');
      return sprintf(s__('SecurityTrackedRefs|Remove tracking for %{refType}'), { refType });
    },
    confirmationMessage() {
      if (!this.refToUntrack) return '';

      return sprintf(
        s__('SecurityTrackedRefs|Are you sure you want to remove tracking from this %{refType}?'),
        {
          refType:
            this.refToUntrack.refType === 'TAG'
              ? s__('SecurityTrackedRefs|tag')
              : s__('SecurityTrackedRefs|branch'),
        },
      );
    },
    vulnerabilityCount() {
      return this.refToUntrack?.vulnerabilitiesCount || 0;
    },
    vulnerabilityWarningMessage() {
      return n__(
        'SecurityTrackedRefs|The data for %{count} vulnerability will be permanently deleted.',
        'SecurityTrackedRefs|The data for %{count} vulnerabilities will be permanently deleted.',
        this.vulnerabilityCount,
      );
    },
    actionPrimaryProps() {
      return {
        text: s__('SecurityTrackedRefs|Remove tracking'),
        attributes: {
          variant: 'danger',
        },
      };
    },
    actionCancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    confirmUntrack() {
      this.$emit('confirm', {
        refId: this.refToUntrack.id,
      });
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="refToUntrack !== null"
    :title="modalTitle"
    :action-primary="actionPrimaryProps"
    :action-cancel="actionCancelProps"
    modal-id="untrack-ref-confirmation-modal"
    size="sm"
    @primary="confirmUntrack"
    @hidden="$emit('cancel')"
  >
    <p>{{ confirmationMessage }}</p>
    <p v-if="vulnerabilityCount > 0">
      <gl-sprintf :message="vulnerabilityWarningMessage">
        <template #count>
          <gl-badge variant="neutral" class="gl-mx-1">{{ vulnerabilityCount }}</gl-badge>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
