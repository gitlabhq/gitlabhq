<script>
import { GlIcon, GlLoadingIcon, GlTooltip, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import AlertStatus from '../alert_status.vue';

export default {
  statuses: {
    TRIGGERED: s__('AlertManagement|Triggered'),
    ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
    RESOLVED: s__('AlertManagement|Resolved'),
  },
  components: {
    GlIcon,
    GlLoadingIcon,
    GlTooltip,
    GlSprintf,
    AlertStatus,
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
      const { dropdown } = this.$children[2].$refs.dropdown.$refs;
      if (dropdown && this.isDropdownShowing) {
        dropdown.show();
      }
    },
    handleUpdating(updating) {
      this.isUpdating = updating;
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

      <alert-status
        :alert="alert"
        :project-path="projectPath"
        :is-dropdown-showing="isDropdownShowing"
        :is-sidebar="true"
        @alert-error="$emit('alert-error', $event)"
        @hide-dropdown="hideDropdown"
        @handle-updating="handleUpdating"
      />

      <gl-loading-icon v-if="isUpdating" :inline="true" />
      <p
        v-else-if="!isDropdownShowing"
        class="value gl-m-0"
        :class="{ 'no-value': !$options.statuses[alert.status] }"
      >
        <span
          v-if="$options.statuses[alert.status]"
          class="gl-text-gray-500"
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
