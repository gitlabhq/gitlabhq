<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import Select2Select from '~/vue_shared/components/select2_select.vue';
import { __ } from '~/locale';
import ImportStatus from './import_status.vue';

export default {
  name: 'ProviderRepoTableRow',
  components: {
    Select2Select,
    ImportStatus,
    GlIcon,
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
    <td class="d-flex flex-wrap flex-lg-nowrap">
      <select2-select v-model="targetNamespaceSelect" :options="select2Options" />
      <span class="px-2 import-slash-divider d-flex justify-content-center align-items-center"
        >/</span
      >
      <input
        v-model="newNameInput"
        type="text"
        class="form-control import-project-name-input qa-project-path-field"
      />
    </td>
    <td>
      <import-status :status="repo.importStatus" />
    </td>
    <td>
      <button
        type="button"
        class="qa-import-button btn btn-default"
        @click="fetchImport(repo.importSource.id)"
      >
        {{ importButtonText }}
      </button>
    </td>
  </tr>
</template>
