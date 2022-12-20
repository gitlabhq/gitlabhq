<script>
import {
  GlIcon,
  GlBadge,
  GlFormInput,
  GlButton,
  GlLink,
  GlDropdownItem,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlTooltip,
} from '@gitlab/ui';
import { mapState, mapGetters, mapActions } from 'vuex';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import ImportGroupDropdown from '../../components/group_dropdown.vue';
import ImportStatus from '../../components/import_status.vue';
import { STATUSES } from '../../constants';
import { isProjectImportable, isImporting, isIncompatible, getImportStatus } from '../utils';

export default {
  name: 'ProviderRepoTableRow',
  components: {
    ImportGroupDropdown,
    ImportStatus,
    GlFormInput,
    GlButton,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlIcon,
    GlBadge,
    GlLink,
    GlTooltip,
  },
  props: {
    repo: {
      type: Object,
      required: true,
    },
    userNamespace: {
      type: String,
      required: true,
    },
    optionalStages: {
      type: Object,
      required: true,
    },
    cancelable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    ...mapState(['ciCdOnly']),
    ...mapGetters(['getImportTarget']),

    displayFullPath() {
      return this.repo.importedProject.fullPath.replace(/^\//, '');
    },

    isFinished() {
      return this.repo.importedProject?.importStatus === STATUSES.FINISHED;
    },

    isImportNotStarted() {
      return isProjectImportable(this.repo);
    },

    isIncompatible() {
      return isIncompatible(this.repo);
    },

    importStatus() {
      return getImportStatus(this.repo);
    },

    isImporting() {
      return isImporting(this.repo);
    },

    isCancelable() {
      return this.cancelable && this.isImporting && this.importStatus !== STATUSES.SCHEDULING;
    },

    stats() {
      return this.repo.importedProject?.stats;
    },

    importTarget() {
      return this.getImportTarget(this.repo.importSource.id);
    },

    importButtonText() {
      return this.ciCdOnly ? __('Connect') : __('Import');
    },

    newNameInput: {
      get() {
        return this.importTarget.newName;
      },
      set(value) {
        this.updateImportTarget({ newName: value });
      },
    },
  },

  methods: {
    ...mapActions(['fetchImport', 'cancelImport', 'setImportTarget']),
    updateImportTarget(changedValues) {
      this.setImportTarget({
        repoId: this.repo.importSource.id,
        importTarget: { ...this.importTarget, ...changedValues },
      });
    },
  },

  helpUrl: helpPagePath('/user/project/import/github.md'),
};
</script>

<template>
  <tr
    class="gl-h-11 gl-border-0 gl-border-solid gl-border-t-1 gl-border-gray-100 gl-h-11 gl-vertical-align-top"
    data-qa-selector="project_import_row"
    :data-qa-source-project="repo.importSource.fullName"
  >
    <td class="gl-p-4 gl-vertical-align-top">
      <gl-link :href="repo.importSource.providerLink" target="_blank" data-testid="providerLink"
        >{{ repo.importSource.fullName }}
        <gl-icon v-if="repo.importSource.providerLink" name="external-link" />
      </gl-link>
    </td>
    <td
      class="gl-display-flex gl-sm-flex-wrap gl-p-4 gl-pt-5 gl-vertical-align-top"
      data-testid="fullPath"
      data-qa-selector="project_path_content"
    >
      <template v-if="repo.importSource.target">{{ repo.importSource.target }}</template>
      <template v-else-if="isImportNotStarted">
        <div class="import-entities-target-select gl-display-flex gl-align-items-stretch gl-w-full">
          <import-group-dropdown #default="{ namespaces }" :text="importTarget.targetNamespace">
            <template v-if="namespaces.length">
              <gl-dropdown-section-header>{{ __('Groups') }}</gl-dropdown-section-header>
              <gl-dropdown-item
                v-for="ns in namespaces"
                :key="ns.fullPath"
                data-qa-selector="target_group_dropdown_item"
                :data-qa-group-name="ns.fullPath"
                @click="updateImportTarget({ targetNamespace: ns.fullPath })"
              >
                {{ ns.fullPath }}
              </gl-dropdown-item>
              <gl-dropdown-divider />
            </template>
            <gl-dropdown-section-header>{{ __('Users') }}</gl-dropdown-section-header>
            <gl-dropdown-item @click="updateImportTarget({ targetNamespace: userNamespace })">{{
              userNamespace
            }}</gl-dropdown-item>
          </import-group-dropdown>
          <div
            class="import-entities-target-select-separator gl-px-3 gl-display-flex gl-align-items-center gl-border-solid gl-border-0 gl-border-t-1 gl-border-b-1"
          >
            /
          </div>
          <gl-form-input
            v-model="newNameInput"
            class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
            data-qa-selector="project_path_field"
          />
        </div>
      </template>
      <template v-else-if="repo.importedProject">{{ displayFullPath }}</template>
    </td>
    <td class="gl-p-4 gl-vertical-align-top" data-qa-selector="import_status_indicator">
      <import-status :status="importStatus" :stats="stats" />
    </td>
    <td data-testid="actions" class="gl-vertical-align-top gl-pt-4">
      <gl-tooltip :target="() => $refs.cancelButton.$el">
        <div class="gl-text-left">
          <p class="gl-mb-5 gl-font-weight-bold">{{ s__('ImportProjects|Cancel import') }}</p>
          {{
            s__(
              'ImportProjects|Imported files will be kept. You can import this repository again later.',
            )
          }}
          <gl-link :href="$options.helpUrl" target="_blank">{{ __('Learn more.') }}</gl-link>
        </div>
      </gl-tooltip>
      <gl-button
        v-show="isCancelable"
        ref="cancelButton"
        variant="danger"
        category="secondary"
        icon="cancel"
        :aria-label="__('Cancel')"
        @click="cancelImport({ repoId: repo.importSource.id })"
      />
      <gl-button
        v-if="isFinished"
        class="btn btn-default"
        :href="repo.importedProject.fullPath"
        rel="noreferrer noopener"
        target="_blank"
        data-qa-selector="go_to_project_button"
        >{{ __('Go to project') }}
      </gl-button>
      <gl-button
        v-if="isImportNotStarted"
        type="button"
        data-qa-selector="import_button"
        @click="fetchImport({ repoId: repo.importSource.id, optionalStages })"
      >
        {{ importButtonText }}
      </gl-button>
      <gl-badge v-else-if="isIncompatible" variant="danger">{{
        __('Incompatible project')
      }}</gl-badge>
    </td>
  </tr>
</template>
