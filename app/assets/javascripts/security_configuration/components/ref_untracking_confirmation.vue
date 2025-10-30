<script>
import { GlModal, GlFormCheckbox, GlBadge, GlSprintf } from '@gitlab/ui';
import { __, sprintf, n__, s__ } from '~/locale';

export default {
  components: {
    GlModal,
    GlFormCheckbox,
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
  data() {
    return {
      archiveVulnerabilities: true,
    };
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
        'SecurityTrackedRefs|If you do not archive associated vulnerabilities, the data for %{count} vulnerability will be permanently deleted.',
        'SecurityTrackedRefs|If you do not archive associated vulnerabilities, the data for %{count} vulnerabilities will be permanently deleted.',
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
        archiveVulnerabilities: this.archiveVulnerabilities,
      });
    },
    enableArchiveVulnerabilities() {
      // This ensures that the checkbox is always checked when the modal is opened
      this.archiveVulnerabilities = true;
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
    @show="enableArchiveVulnerabilities"
  >
    <p>{{ confirmationMessage }}</p>
    <p>
      <gl-sprintf :message="vulnerabilityWarningMessage">
        <template #count>
          <gl-badge variant="neutral" class="gl-mx-1">{{ vulnerabilityCount }}</gl-badge>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-checkbox v-model="archiveVulnerabilities" data-testid="archive-checkbox">
      {{ s__('SecurityTrackedRefs|Archive associated vulnerabilities') }}
    </gl-form-checkbox>
  </gl-modal>
</template>
