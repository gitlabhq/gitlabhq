<script>
import { GlCollapsibleListbox, GlTooltip, GlSprintf } from '@gitlab/ui';
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
    GlCollapsibleListbox,
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
    dropdownItems() {
      return this.severitiesList.map((severity) => ({
        text: severity.label,
        value: severity.value,
        severity,
      }));
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
      this.$refs.dropdown.open();
    },
  },
};
</script>

<template>
  <div ref="sidebarSeverity" class="block" data-testid="severity-block-container">
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
        <div class="hide-collapsed" data-testid="incident-severity">
          <severity-token :severity="selectedItem" />
        </div>
      </template>

      <template #default>
        <gl-collapsible-listbox
          ref="dropdown"
          class="gl-mt-3"
          block
          :header-text="__('Assign severity')"
          :toggle-text="selectedItem.label"
          :items="dropdownItems"
          :selected="severity"
          @select="updateSeverity"
        >
          <template #list-item="{ item }">
            <severity-token :severity="item.severity" />
          </template>
        </gl-collapsible-listbox>
      </template>
    </sidebar-editable-item>
  </div>
</template>
