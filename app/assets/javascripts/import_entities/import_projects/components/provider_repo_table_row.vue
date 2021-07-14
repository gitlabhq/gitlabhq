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
} from '@gitlab/ui';
import { mapState, mapGetters, mapActions } from 'vuex';
import { __ } from '~/locale';
import ImportGroupDropdown from '../../components/group_dropdown.vue';
import ImportStatus from '../../components/import_status.vue';
import { STATUSES } from '../../constants';
import { isProjectImportable, isIncompatible, getImportStatus } from '../utils';

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
    availableNamespaces: {
      type: Array,
      required: true,
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
    ...mapActions(['fetchImport', 'setImportTarget']),
    updateImportTarget(changedValues) {
      this.setImportTarget({
        repoId: this.repo.importSource.id,
        importTarget: { ...this.importTarget, ...changedValues },
      });
    },
  },
};
</script>

<template>
  <tr
    class="gl-h-11 gl-border-0 gl-border-solid gl-border-t-1 gl-border-gray-100 gl-h-11"
    data-qa-selector="project_import_row"
  >
    <td class="gl-p-4">
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
          <import-group-dropdown
            #default="{ namespaces }"
            :text="importTarget.targetNamespace"
            :namespaces="availableNamespaces"
          >
            <template v-if="namespaces.length">
              <gl-dropdown-section-header>{{ __('Groups') }}</gl-dropdown-section-header>
              <gl-dropdown-item
                v-for="ns in namespaces"
                :key="ns"
                data-qa-selector="target_group_dropdown_item"
                :data-qa-group-name="ns"
                @click="updateImportTarget({ targetNamespace: ns })"
              >
                {{ ns }}
              </gl-dropdown-item>
              <gl-dropdown-divider />
            </template>
            <gl-dropdown-section-header>{{ __('Users') }}</gl-dropdown-section-header>
            <gl-dropdown-item @click="updateImportTarget({ targetNamespace: ns })">{{
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
    <td class="gl-p-4">
      <import-status :status="importStatus" />
    </td>
    <td data-testid="actions">
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
        @click="fetchImport(repo.importSource.id)"
      >
        {{ importButtonText }}
      </gl-button>
      <gl-badge v-else-if="isIncompatible" variant="danger">{{
        __('Incompatible project')
      }}</gl-badge>
    </td>
  </tr>
</template>
