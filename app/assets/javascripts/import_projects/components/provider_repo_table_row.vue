<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlIcon, GlBadge } from '@gitlab/ui';
import Select2Select from '~/vue_shared/components/select2_select.vue';
import { __ } from '~/locale';
import ImportStatus from './import_status.vue';
import { STATUSES } from '../constants';
import { isProjectImportable, isIncompatible, getImportStatus } from '../utils';

export default {
  name: 'ProviderRepoTableRow',
  components: {
    Select2Select,
    ImportStatus,
    GlIcon,
    GlBadge,
  },
  props: {
    repo: {
      type: Object,
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

    select2Options() {
      return {
        data: this.availableNamespaces,
        containerCssClass: 'import-namespace-select qa-project-namespace-select w-auto',
      };
    },

    targetNamespaceSelect: {
      get() {
        return this.importTarget.targetNamespace;
      },
      set(value) {
        this.updateImportTarget({ targetNamespace: value });
      },
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
  <tr class="qa-project-import-row import-row">
    <td>
      <a
        :href="repo.importSource.providerLink"
        rel="noreferrer noopener"
        target="_blank"
        data-testid="providerLink"
        >{{ repo.importSource.fullName }}
        <gl-icon v-if="repo.importSource.providerLink" name="external-link" />
      </a>
    </td>
    <td class="d-flex flex-wrap flex-lg-nowrap" data-testid="fullPath">
      <template v-if="repo.importSource.target">{{ repo.importSource.target }}</template>
      <template v-else-if="isImportNotStarted">
        <select2-select v-model="targetNamespaceSelect" :options="select2Options" />
        <span class="px-2 import-slash-divider d-flex justify-content-center align-items-center"
          >/</span
        >
        <input
          v-model="newNameInput"
          type="text"
          class="form-control import-project-name-input qa-project-path-field"
        />
      </template>
      <template v-else-if="repo.importedProject">{{ displayFullPath }}</template>
    </td>
    <td>
      <import-status :status="importStatus" />
    </td>
    <td data-testid="actions">
      <a
        v-if="isFinished"
        class="btn btn-default"
        :href="repo.importedProject.fullPath"
        rel="noreferrer noopener"
        target="_blank"
        >{{ __('Go to project') }}
      </a>
      <button
        v-if="isImportNotStarted"
        type="button"
        class="qa-import-button btn btn-default"
        @click="fetchImport(repo.importSource.id)"
      >
        {{ importButtonText }}
      </button>
      <gl-badge v-else-if="isIncompatible" variant="danger">{{
        __('Incompatible project')
      }}</gl-badge>
    </td>
  </tr>
</template>
