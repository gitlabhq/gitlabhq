<script>
import { GlButton, GlIcon, GlLoadingIcon, GlTooltip, GlSprintf } from '@gitlab/ui';
import { PAGE_CONFIG } from '../../constants';
import AlertStatus from '../alert_status.vue';

export default {
  components: {
    GlIcon,
    GlButton,
    GlLoadingIcon,
    GlTooltip,
    GlSprintf,
    AlertStatus,
  },
  inject: {
    statuses: {
      default: PAGE_CONFIG.OPERATIONS.STATUSES,
    },
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
    sidebarCollapsed: {
      type: Boolean,
      required: false,
    },
    textClass: {
      type: String,
      required: false,
      default: '',
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
      const { dropdown } = this.$refs.status.$refs.dropdown.$refs;
      if (dropdown && this.isDropdownShowing) {
        dropdown.show();
      }
    },
    handleUpdating(isMutationInProgress) {
      if (!isMutationInProgress) {
        this.$emit('alert-update');
      }
      this.isUpdating = isMutationInProgress;
    },
  },
};
</script>

<template>
  <div
    class="alert-status gl-py-5"
    :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': !sidebarCollapsed }"
  >
    <template v-if="sidebarCollapsed">
      <div ref="status" class="gl-ml-6" data-testid="status-icon" @click="$emit('toggle-sidebar')">
        <gl-icon name="status" />
        <gl-loading-icon v-if="isUpdating" size="sm" />
      </div>
      <gl-tooltip :target="() => $refs.status" boundary="viewport" placement="left">
        <gl-sprintf :message="s__('AlertManagement|Alert status: %{status}')">
          <template #status>
            {{ alert.status.toLowerCase() }}
          </template>
        </gl-sprintf>
      </gl-tooltip>
    </template>

    <div v-else>
      <p
        class="gl-text-gray-900 gl-mb-2 gl-line-height-20 gl-display-flex gl-justify-content-space-between"
      >
        {{ s__('AlertManagement|Status') }}
        <gl-button
          v-if="isEditable"
          class="gl-text-black-normal!"
          variant="link"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ s__('AlertManagement|Edit') }}
        </gl-button>
      </p>

      <alert-status
        ref="status"
        :alert="alert"
        :project-path="projectPath"
        :is-dropdown-showing="isDropdownShowing"
        :is-sidebar="true"
        :statuses="statuses"
        @alert-error="$emit('alert-error', $event)"
        @hide-dropdown="hideDropdown"
        @handle-updating="handleUpdating"
      />

      <gl-loading-icon v-if="isUpdating" size="sm" :inline="true" />
      <p
        v-else-if="!isDropdownShowing"
        class="value gl-m-0"
        :class="{ 'no-value': !statuses[alert.status] }"
      >
        <span v-if="statuses[alert.status]" :class="textClass" data-testid="status">
          {{ statuses[alert.status] }}
        </span>
        <span v-else>
          {{ s__('AlertManagement|None') }}
        </span>
      </p>
    </div>
  </div>
</template>
