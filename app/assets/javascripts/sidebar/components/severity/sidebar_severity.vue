<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlLoadingIcon,
  GlTooltip,
  GlSprintf,
  GlButton,
} from '@gitlab/ui';
import { createAlert } from '~/flash';
import updateIssuableSeverity from '../../queries/update_issuable_severity.mutation.graphql';
import { INCIDENT_SEVERITY, ISSUABLE_TYPES, I18N } from './constants';
import SeverityToken from './severity.vue';

export default {
  i18n: I18N,
  components: {
    GlLoadingIcon,
    GlTooltip,
    GlSprintf,
    GlDropdown,
    GlDropdownItem,
    GlButton,
    SeverityToken,
  },
  inject: ['canUpdate'],
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    initialSeverity: {
      type: String,
      required: false,
      default: INCIDENT_SEVERITY.UNKNOWN.value,
    },
    issuableType: {
      type: String,
      required: false,
      default: ISSUABLE_TYPES.INCIDENT,
      validator: (value) => {
        // currently severity is supported only for incidents, but this list might be extended
        return [ISSUABLE_TYPES.INCIDENT].includes(value);
      },
    },
  },
  data() {
    return {
      isDropdownShowing: false,
      isUpdating: false,
      severity: this.initialSeverity,
    };
  },
  computed: {
    severitiesList() {
      switch (this.issuableType) {
        case ISSUABLE_TYPES.INCIDENT:
          return Object.values(INCIDENT_SEVERITY);
        default:
          return [];
      }
    },
    dropdownClass() {
      return this.isDropdownShowing ? 'show' : 'gl-display-none';
    },
    selectedItem() {
      return this.severitiesList.find((severity) => severity.value === this.severity);
    },
  },
  mounted() {
    document.addEventListener('click', this.handleOffClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleOffClick);
  },
  methods: {
    handleOffClick(event) {
      if (!this.isDropdownShowing) {
        return;
      }

      if (!this.$refs.sidebarSeverity.contains(event.target)) {
        this.hideDropdown();
      }
    },
    hideDropdown() {
      this.isDropdownShowing = false;
      const event = new Event('hidden.gl.dropdown');
      this.$el.dispatchEvent(event);
    },
    toggleFormDropdown() {
      this.isDropdownShowing = !this.isDropdownShowing;
    },
    updateSeverity(value) {
      this.hideDropdown();
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: updateIssuableSeverity,
          variables: {
            iid: this.iid,
            severity: value,
            projectPath: this.projectPath,
          },
        })
        .then((resp) => {
          const {
            data: {
              issueSetSeverity: {
                errors = [],
                issue: { severity },
              },
            },
          } = resp;

          if (errors[0]) {
            throw errors[0];
          }
          this.severity = severity;
        })
        .catch(() =>
          createAlert({
            message: `${this.$options.i18n.UPDATE_SEVERITY_ERROR} ${this.$options.i18n.TRY_AGAIN}`,
          }),
        )
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <div ref="sidebarSeverity" class="block">
    <div ref="severity" class="sidebar-collapsed-icon" @click="toggleFormDropdown">
      <severity-token :severity="selectedItem" :icon-size="14" :icon-only="true" />
      <gl-tooltip :target="() => $refs.severity" boundary="viewport" placement="left">
        <gl-sprintf :message="$options.i18n.SEVERITY_VALUE">
          <template #severity>
            {{ selectedItem.label }}
          </template>
        </gl-sprintf>
      </gl-tooltip>
    </div>

    <div class="hide-collapsed">
      <div
        class="gl-display-flex gl-align-items-center gl-line-height-20 gl-text-gray-900 gl-font-weight-bold"
      >
        {{ $options.i18n.SEVERITY }}
        <gl-button
          v-if="canUpdate"
          category="tertiary"
          size="small"
          class="gl-ml-auto hide-collapsed gl-mr-n2"
          data-testid="editButton"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ $options.i18n.EDIT }}
        </gl-button>
      </div>

      <gl-dropdown
        class="gl-mt-3"
        :class="dropdownClass"
        block
        :header-text="__('Assign severity')"
        :text="selectedItem.label"
        toggle-class="dropdown-menu-toggle gl-mb-2"
        @keydown.esc.native="hideDropdown"
      >
        <gl-dropdown-item
          v-for="option in severitiesList"
          :key="option.value"
          data-testid="severityDropdownItem"
          is-check-item
          :is-checked="option.value === severity"
          @click="updateSeverity(option.value)"
        >
          <severity-token :severity="option" />
        </gl-dropdown-item>
      </gl-dropdown>

      <gl-loading-icon v-if="isUpdating" size="sm" :inline="true" />

      <severity-token v-else-if="!isDropdownShowing" :severity="selectedItem" />
    </div>
  </div>
</template>
