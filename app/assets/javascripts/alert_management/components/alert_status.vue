<script>
import { GlDeprecatedDropdown, GlDeprecatedDropdownItem, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { trackAlertStatusUpdateOptions } from '../constants';
import updateAlertStatus from '../graphql/mutations/update_alert_status.mutation.graphql';

export default {
  i18n: {
    UPDATE_ALERT_STATUS_ERROR: s__(
      'AlertManagement|There was an error while updating the status of the alert.',
    ),
    UPDATE_ALERT_STATUS_INSTRUCTION: s__('AlertManagement|Please try again.'),
  },
  statuses: {
    TRIGGERED: s__('AlertManagement|Triggered'),
    ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
    RESOLVED: s__('AlertManagement|Resolved'),
  },
  components: {
    GlDeprecatedDropdown,
    GlDeprecatedDropdownItem,
    GlButton,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    alert: {
      type: Object,
      required: true,
    },
    isDropdownShowing: {
      type: Boolean,
      required: false,
    },
    isSidebar: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    dropdownClass() {
      // eslint-disable-next-line no-nested-ternary
      return this.isSidebar ? (this.isDropdownShowing ? 'show' : 'gl-display-none') : '';
    },
  },
  methods: {
    updateAlertStatus(status) {
      this.$emit('handle-updating', true);
      this.$apollo
        .mutate({
          mutation: updateAlertStatus,
          variables: {
            iid: this.alert.iid,
            status: status.toUpperCase(),
            projectPath: this.projectPath,
          },
        })
        .then(resp => {
          this.trackStatusUpdate(status);
          this.$emit('hide-dropdown');

          const errors = resp.data?.updateAlertStatus?.errors || [];

          if (errors[0]) {
            this.$emit(
              'alert-error',
              `${this.$options.i18n.UPDATE_ALERT_STATUS_ERROR} ${errors[0]}`,
            );
          }
        })
        .catch(() => {
          this.$emit(
            'alert-error',
            `${this.$options.i18n.UPDATE_ALERT_STATUS_ERROR} ${this.$options.i18n.UPDATE_ALERT_STATUS_INSTRUCTION}`,
          );
        })
        .finally(() => {
          this.$emit('handle-updating', false);
        });
    },
    trackStatusUpdate(status) {
      const { category, action, label } = trackAlertStatusUpdateOptions;
      Tracking.event(category, action, { label, property: status });
    },
  },
};
</script>

<template>
  <div class="dropdown dropdown-menu-selectable" :class="dropdownClass">
    <gl-deprecated-dropdown
      ref="dropdown"
      right
      :text="$options.statuses[alert.status]"
      class="w-100"
      toggle-class="dropdown-menu-toggle"
      variant="outline-default"
      @keydown.esc.native="$emit('hide-dropdown')"
      @hide="$emit('hide-dropdown')"
    >
      <div v-if="isSidebar" class="dropdown-title gl-display-flex">
        <span class="alert-title gl-ml-auto">{{ s__('AlertManagement|Assign status') }}</span>
        <gl-button
          :aria-label="__('Close')"
          variant="link"
          class="dropdown-title-button dropdown-menu-close gl-ml-auto gl-text-black-normal!"
          icon="close"
          @click="$emit('hide-dropdown')"
        />
      </div>
      <div class="dropdown-content dropdown-body">
        <gl-deprecated-dropdown-item
          v-for="(label, field) in $options.statuses"
          :key="field"
          data-testid="statusDropdownItem"
          class="gl-vertical-align-middle"
          :active="label.toUpperCase() === alert.status"
          :active-class="'is-active'"
          @click="updateAlertStatus(label)"
        >
          {{ label }}
        </gl-deprecated-dropdown-item>
      </div>
    </gl-deprecated-dropdown>
  </div>
</template>
