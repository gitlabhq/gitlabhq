<script>
import { GlDropdown, GlDropdownItem, GlTooltip, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPE_INCIDENT } from '~/issues/constants';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import updateIssuableSeverity from '../../queries/update_issuable_severity.mutation.graphql';
import { INCIDENT_SEVERITY, SEVERITY_I18N as I18N } from '../../constants';
import SeverityToken from './severity.vue';

export default {
  i18n: I18N,
  components: {
    GlTooltip,
    GlSprintf,
    GlDropdown,
    GlDropdownItem,
    SeverityToken,
    SidebarEditableItem,
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
      default: TYPE_INCIDENT,
      validator: (value) => {
        // currently severity is supported only for incidents, but this list might be extended
        return [TYPE_INCIDENT].includes(value);
      },
    },
  },
  data() {
    return {
      isUpdating: false,
      severity: this.initialSeverity,
    };
  },
  computed: {
    severitiesList() {
      switch (this.issuableType) {
        case TYPE_INCIDENT:
          return Object.values(INCIDENT_SEVERITY);
        default:
          return [];
      }
    },
    selectedItem() {
      return this.severitiesList.find((severity) => severity.value === this.severity);
    },
  },
  methods: {
    updateSeverity(value) {
      this.$refs.toggle.collapse();
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
    showDropdown() {
      this.$refs.dropdown.show();
    },
  },
};
</script>

<template>
  <div ref="sidebarSeverity" class="block">
    <sidebar-editable-item
      ref="toggle"
      :loading="isUpdating"
      :title="$options.i18n.SEVERITY"
      :can-edit="canUpdate"
      @open="showDropdown"
    >
      <template #collapsed>
        <div ref="severity" class="sidebar-collapsed-icon">
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
          <severity-token :severity="selectedItem" />
        </div>
      </template>

      <template #default>
        <gl-dropdown
          ref="dropdown"
          class="gl-mt-3"
          block
          :header-text="__('Assign severity')"
          :text="selectedItem.label"
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
      </template>
    </sidebar-editable-item>
  </div>
</template>
