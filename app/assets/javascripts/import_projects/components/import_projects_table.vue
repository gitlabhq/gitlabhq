<script>
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import ImportedProjectTableRow from './imported_project_table_row.vue';
import ProviderRepoTableRow from './provider_repo_table_row.vue';
import IncompatibleRepoTableRow from './incompatible_repo_table_row.vue';
import { isProjectImportable } from '../utils';

const reposFetchThrottleDelay = 1000;

export default {
  name: 'ImportProjectsTable',
  components: {
    ImportedProjectTableRow,
    ProviderRepoTableRow,
    IncompatibleRepoTableRow,
    GlLoadingIcon,
    GlButton,
  },
  props: {
    providerTitle: {
      type: String,
      required: true,
    },
    filterable: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  computed: {
    ...mapState(['filter', 'repositories', 'namespaces', 'defaultTargetNamespace']),
    ...mapGetters([
      'isLoading',
      'isImportingAnyRepo',
      'hasImportableRepos',
      'hasIncompatibleRepos',
    ]),

    availableNamespaces() {
      const serializedNamespaces = this.namespaces.map(({ fullPath }) => ({
        id: fullPath,
        text: fullPath,
      }));

      return [
        { text: __('Groups'), children: serializedNamespaces },
        {
          text: __('Users'),
          children: [{ id: this.defaultTargetNamespace, text: this.defaultTargetNamespace }],
        },
      ];
    },

    importAllButtonText() {
      return this.hasIncompatibleRepos
        ? __('Import all compatible repositories')
        : __('Import all repositories');
    },

    emptyStateText() {
      return sprintf(__('No %{providerTitle} repositories found'), {
        providerTitle: this.providerTitle,
      });
    },

    fromHeaderText() {
      return sprintf(__('From %{providerTitle}'), { providerTitle: this.providerTitle });
    },
  },

  mounted() {
    this.fetchNamespaces();
    this.fetchRepos();
  },

  beforeDestroy() {
    this.stopJobsPolling();
    this.clearJobsEtagPoll();
  },

  methods: {
    ...mapActions([
      'fetchRepos',
      'fetchNamespaces',
      'stopJobsPolling',
      'clearJobsEtagPoll',
      'setFilter',
      'importAll',
    ]),

    handleFilterInput({ target }) {
      this.setFilter(target.value);
    },

    throttledFetchRepos: throttle(function fetch() {
      this.fetchRepos();
    }, reposFetchThrottleDelay),

    isProjectImportable,
  },
};
</script>

<template>
  <div>
    <p class="light text-nowrap mt-2">
      {{ s__('ImportProjects|Select the projects you want to import') }}
    </p>
    <template v-if="hasIncompatibleRepos">
      <slot name="incompatible-repos-warning"></slot>
    </template>
    <div v-if="!isLoading" class="d-flex justify-content-between align-items-end flex-wrap mb-3">
      <gl-button
        variant="success"
        :loading="isImportingAnyRepo"
        :disabled="!hasImportableRepos"
        type="button"
        @click="importAll"
        >{{ importAllButtonText }}</gl-button
      >
      <slot name="actions"></slot>
      <form v-if="filterable" class="gl-ml-auto" novalidate @submit.prevent>
        <input
          :value="filter"
          data-qa-selector="githubish_import_filter_field"
          class="form-control"
          name="filter"
          :placeholder="__('Filter your projects by name')"
          autofocus
          size="40"
          @input="handleFilterInput($event)"
          @keyup.enter="throttledFetchRepos"
        />
      </form>
    </div>
    <gl-loading-icon
      v-if="isLoading"
      class="js-loading-button-icon import-projects-loading-icon"
      size="md"
    />
    <div v-else-if="repositories.length" class="table-responsive">
      <table class="table import-table">
        <thead>
          <th class="import-jobs-from-col">{{ fromHeaderText }}</th>
          <th class="import-jobs-to-col">{{ __('To GitLab') }}</th>
          <th class="import-jobs-status-col">{{ __('Status') }}</th>
          <th class="import-jobs-cta-col"></th>
        </thead>
        <tbody>
          <template v-for="repo in repositories">
            <incompatible-repo-table-row
              v-if="repo.importSource.incompatible"
              :key="repo.importSource.id"
              :repo="repo"
            />
            <provider-repo-table-row
              v-else-if="isProjectImportable(repo)"
              :key="repo.importSource.id"
              :repo="repo"
              :available-namespaces="availableNamespaces"
            />
            <imported-project-table-row v-else :key="repo.importSource.id" :project="repo" />
          </template>
        </tbody>
      </table>
    </div>
    <div v-else class="text-center">
      <strong>{{ emptyStateText }}</strong>
    </div>
  </div>
</template>
