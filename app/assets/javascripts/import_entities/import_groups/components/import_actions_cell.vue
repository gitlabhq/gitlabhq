<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlButtonGroup,
  GlButton,
  GlLink,
  GlTooltip,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButtonGroup,
    GlButton,
    GlLink,
    GlTooltip,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  projectCreationHelp: helpPagePath('user/group/import/index', {
    anchor: 'ensure-projects-can-be-imported',
  }),
  props: {
    id: {
      type: Number,
      required: false,
      default: null,
    },
    isFinished: {
      type: Boolean,
      required: true,
    },
    isAvailableForImport: {
      type: Boolean,
      required: true,
    },
    isInvalid: {
      type: Boolean,
      required: true,
    },
    isProjectCreationAllowed: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  computed: {
    showImportActions() {
      return this.isAvailableForImport || this.isFinished;
    },
    showImportWithoutProjectsWarning() {
      return this.showImportActions && !this.isProjectCreationAllowed;
    },
    importWithProjectsText() {
      return this.isFinished ? __('Re-import with projects') : __('Import with projects');
    },
    importWithoutProjectsText() {
      return this.isFinished ? __('Re-import without projects') : __('Import without projects');
    },
  },

  methods: {
    importGroup(extraArgs = {}) {
      this.$emit('import-group', extraArgs);
    },
  },
};
</script>

<template>
  <div class="gl-white-space-nowrap gl-display-inline-flex gl-align-items-center gl-gap-3">
    <template v-if="isProjectCreationAllowed">
      <gl-button-group v-if="showImportActions">
        <gl-button
          variant="confirm"
          category="secondary"
          data-testid="import-group-button"
          @click="importGroup({ migrateProjects: true })"
          >{{ importWithProjectsText }}</gl-button
        >
        <gl-disclosure-dropdown
          toggle-text="Import options"
          text-sr-only
          :disabled="isInvalid"
          icon="chevron-down"
          no-caret
          variant="confirm"
          category="secondary"
        >
          <gl-disclosure-dropdown-item @action="importGroup({ migrateProjects: false })">
            <template #list-item>
              {{ importWithoutProjectsText }}
            </template></gl-disclosure-dropdown-item
          >
        </gl-disclosure-dropdown>
      </gl-button-group>
    </template>
    <template v-else>
      <gl-button
        v-if="showImportActions"
        variant="confirm"
        category="secondary"
        data-testid="import-group-button"
        @click="importGroup({ migrateProjects: false })"
      >
        {{ importWithoutProjectsText }}
      </gl-button>
    </template>

    <gl-icon
      v-if="isFinished"
      v-gl-tooltip
      name="information-o"
      data-testid="reimport-info-icon"
      :title="
        s__('BulkImport|Re-import creates a new group. It does not sync with the existing group.')
      "
    />

    <div v-if="showImportWithoutProjectsWarning" :id="`tooltip-description-container-${id}`">
      <span ref="projectCreationWarning">
        <gl-icon
          name="warning"
          class="gl-text-orange-500"
          data-testid="project-creation-warning-icon"
        />
      </span>

      <gl-tooltip
        :target="() => $refs.projectCreationWarning"
        :container="`tooltip-description-container-${id}`"
      >
        <gl-sprintf
          :message="
            s__(
              `BulkImport|Because of settings on the source GitLab instance or group, you can't import projects with this group. To permit importing projects with this group, reconfigure the source GitLab instance or group. %{linkStart}Learn more.%{linkEnd}`,
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.projectCreationHelp" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-tooltip>
    </div>
  </div>
</template>
