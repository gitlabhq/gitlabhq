<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButtonGroup,
  GlButton,
  GlLink,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

export default {
  components: {
    HelpPopover,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButtonGroup,
    GlButton,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  projectCreationHelp: helpPagePath('user/group/import/direct_transfer_migrations', {
    anchor: 'configuration',
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
  <div class="gl-inline-flex gl-items-center gl-gap-3 gl-whitespace-nowrap">
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

    <help-popover v-if="isFinished" icon="information-o" data-testid="reimport-info-icon">
      {{
        s__('BulkImport|Re-import creates a new group. It does not sync with the existing group.')
      }}
    </help-popover>

    <help-popover
      v-if="showImportWithoutProjectsWarning"
      icon="warning"
      trigger-class="!gl-text-warning"
      data-testid="project-creation-warning-icon"
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
    </help-popover>
  </div>
</template>
