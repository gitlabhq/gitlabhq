<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlLoadingIcon,
  GlTooltip,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import createFlash from '~/flash';
import { INCIDENT_SEVERITY, ISSUABLE_TYPES, I18N } from './constants';
import updateIssuableSeverity from './graphql/mutations/update_issuable_severity.mutation.graphql';
import SeverityToken from './severity.vue';

export default {
  i18n: I18N,
  components: {
    GlLoadingIcon,
    GlTooltip,
    GlSprintf,
    GlDropdown,
    GlDropdownItem,
    GlLink,
    SeverityToken,
  },
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
          createFlash({
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
      <p
        class="gl-line-height-20 gl-mb-0 gl-text-gray-900 gl-display-flex gl-justify-content-space-between"
      >
        {{ $options.i18n.SEVERITY }}
        <gl-link
          data-testid="editButton"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ $options.i18n.EDIT }}
        </gl-link>
      </p>

      <gl-dropdown
        :class="dropdownClass"
        block
        :text="selectedItem.label"
        toggle-class="dropdown-menu-toggle gl-mb-2"
        @keydown.esc.native="hideDropdown"
      >
        <gl-dropdown-item
          v-for="option in severitiesList"
          :key="option.value"
          data-testid="severityDropdownItem"
          :is-check-item="true"
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
