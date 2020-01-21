<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import Select2Select from '~/vue_shared/components/select2_select.vue';
import { __ } from '~/locale';
import eventHub from '../event_hub';
import { STATUSES } from '../constants';
import ImportStatus from './import_status.vue';

export default {
  name: 'ProviderRepoTableRow',
  components: {
    Select2Select,
    ImportStatus,
  },
  props: {
    repo: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      targetNamespace: this.$store.state.defaultTargetNamespace,
      newName: this.repo.sanitizedName,
    };
  },

  computed: {
    ...mapState(['namespaces', 'reposBeingImported', 'ciCdOnly']),

    ...mapGetters(['namespaceSelectOptions']),

    importButtonText() {
      return this.ciCdOnly ? __('Connect') : __('Import');
    },

    select2Options() {
      return {
        data: this.namespaceSelectOptions,
        containerCssClass:
          'import-namespace-select js-namespace-select qa-project-namespace-select w-auto',
      };
    },

    isLoadingImport() {
      return this.reposBeingImported.includes(this.repo.id);
    },

    status() {
      return this.isLoadingImport ? STATUSES.SCHEDULING : STATUSES.NONE;
    },
  },

  created() {
    eventHub.$on('importAll', () => this.importRepo());
  },

  methods: {
    ...mapActions(['fetchImport']),

    importRepo() {
      return this.fetchImport({
        newName: this.newName,
        targetNamespace: this.targetNamespace,
        repo: this.repo,
      });
    },
  },
};
</script>

<template>
  <tr class="qa-project-import-row js-provider-repo import-row">
    <td>
      <a
        :href="repo.providerLink"
        rel="noreferrer noopener"
        target="_blank"
        class="js-provider-link"
      >
        {{ repo.fullName }}
      </a>
    </td>
    <td class="d-flex flex-wrap flex-lg-nowrap">
      <select2-select v-model="targetNamespace" :options="select2Options" />
      <span class="px-2 import-slash-divider d-flex justify-content-center align-items-center"
        >/</span
      >
      <input
        v-model="newName"
        type="text"
        class="form-control import-project-name-input js-new-name qa-project-path-field"
      />
    </td>
    <td><import-status :status="status" /></td>
    <td>
      <button
        v-if="!isLoadingImport"
        type="button"
        class="qa-import-button js-import-button btn btn-default"
        @click="importRepo"
      >
        {{ importButtonText }}
      </button>
    </td>
  </tr>
</template>
