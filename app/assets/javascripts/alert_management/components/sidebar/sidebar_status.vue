<script>
import {
  GlIcon,
  GlDropdown,
  GlDropdownItem,
  GlLoadingIcon,
  GlTooltip,
  GlButton,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { trackAlertStatusUpdateOptions } from '../../constants';
import updateAlertStatus from '../../graphql/mutations/update_alert_status.graphql';

export default {
  statuses: {
    TRIGGERED: s__('AlertManagement|Triggered'),
    ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
    RESOLVED: s__('AlertManagement|Resolved'),
  },
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlLoadingIcon,
    GlTooltip,
    GlButton,
    GlSprintf,
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
    isEditable: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isDropdownShowing: false,
      isUpdating: false,
    };
  },
  computed: {
    dropdownClass() {
      return this.isDropdownShowing ? 'show' : 'gl-display-none';
    },
  },
  methods: {
    hideDropdown() {
      this.isDropdownShowing = false;
    },
    toggleFormDropdown() {
      this.isDropdownShowing = !this.isDropdownShowing;
      const { dropdown } = this.$refs.dropdown.$refs;
      if (dropdown && this.isDropdownShowing) {
        dropdown.show();
      }
    },
    isSelected(status) {
      return this.alert.status === status;
    },
    updateAlertStatus(status) {
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: updateAlertStatus,
          variables: {
            iid: this.alert.iid,
            status: status.toUpperCase(),
            projectPath: this.projectPath,
          },
        })
        .then(() => {
          this.trackStatusUpdate(status);
          this.hideDropdown();
        })
        .catch(() => {
          this.$emit(
            'alert-sidebar-error',
            s__(
              'AlertManagement|There was an error while updating the status of the alert. Please try again.',
            ),
          );
        })
        .finally(() => {
          this.isUpdating = false;
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
  <div class="block alert-status">
    <div ref="status" class="sidebar-collapsed-icon" @click="$emit('toggle-sidebar')">
      <gl-icon name="status" :size="14" />
      <gl-loading-icon v-if="isUpdating" />
    </div>
    <gl-tooltip :target="() => $refs.status" boundary="viewport" placement="left">
      <gl-sprintf :message="s__('AlertManagement|Alert status: %{status}')">
        <template #status>
          {{ alert.status.toLowerCase() }}
        </template>
      </gl-sprintf>
    </gl-tooltip>

    <div class="hide-collapsed">
      <p class="title gl-display-flex justify-content-between">
        {{ s__('AlertManagement|Status') }}
        <a
          v-if="isEditable"
          ref="editButton"
          class="btn-link"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ s__('AlertManagement|Edit') }}
        </a>
      </p>

      <div class="dropdown dropdown-menu-selectable" :class="dropdownClass">
        <gl-dropdown
          ref="dropdown"
          :text="$options.statuses[alert.status]"
          class="w-100"
          toggle-class="dropdown-menu-toggle"
          variant="outline-default"
          @keydown.esc.native="hideDropdown"
          @hide="hideDropdown"
        >
          <div class="dropdown-title">
            <span class="alert-title">{{ s__('AlertManagement|Assign status') }}</span>
            <gl-button
              :aria-label="__('Close')"
              variant="link"
              class="dropdown-title-button dropdown-menu-close"
              icon="close"
              @click="hideDropdown"
            />
          </div>
          <div class="dropdown-content dropdown-body">
            <gl-dropdown-item
              v-for="(label, field) in $options.statuses"
              :key="field"
              data-testid="statusDropdownItem"
              class="gl-vertical-align-middle"
              :active="label.toUpperCase() === alert.status"
              :active-class="'is-active'"
              @click="updateAlertStatus(label)"
            >
              {{ label }}
            </gl-dropdown-item>
          </div>
        </gl-dropdown>
      </div>

      <gl-loading-icon v-if="isUpdating" :inline="true" />
      <p
        v-else-if="!isDropdownShowing"
        class="value gl-m-0"
        :class="{ 'no-value': !$options.statuses[alert.status] }"
      >
        <span
          v-if="$options.statuses[alert.status]"
          class="gl-text-gray-700"
          data-testid="status"
          >{{ $options.statuses[alert.status] }}</span
        >
        <span v-else>
          {{ s__('AlertManagement|None') }}
        </span>
      </p>
    </div>
  </div>
</template>
