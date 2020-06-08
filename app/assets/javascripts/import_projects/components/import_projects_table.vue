<script>
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import ImportedProjectTableRow from './imported_project_table_row.vue';
import ProviderRepoTableRow from './provider_repo_table_row.vue';
import IncompatibleRepoTableRow from './incompatible_repo_table_row.vue';
import eventHub from '../event_hub';

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
  },

  computed: {
    ...mapState([
      'importedProjects',
      'providerRepos',
      'incompatibleRepos',
      'isLoadingRepos',
      'filter',
    ]),
    ...mapGetters([
      'isImportingAnyRepo',
      'hasProviderRepos',
      'hasImportedProjects',
      'hasIncompatibleRepos',
    ]),

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
    return this.fetchRepos();
  },

  beforeDestroy() {
    this.stopJobsPolling();
    this.clearJobsEtagPoll();
  },

  methods: {
    ...mapActions([
      'fetchRepos',
      'fetchReposFiltered',
      'fetchJobs',
      'stopJobsPolling',
      'clearJobsEtagPoll',
      'setFilter',
    ]),

    importAll() {
      eventHub.$emit('importAll');
    },

    handleFilterInput({ target }) {
      this.setFilter(target.value);
    },

    throttledFetchRepos: throttle(function fetch() {
      this.fetchRepos();
    }, reposFetchThrottleDelay),
  },
};
</script>

<template>
  <div>
    <p class="light text-nowrap mt-2">
      {{ s__('ImportProjects|Select the projects you want to import') }}
    </p>
    <template v-if="hasIncompatibleRepos">
      <slot name="incompatible-repos-warning"> </slot>
    </template>
    <div
      v-if="!isLoadingRepos"
      class="d-flex justify-content-between align-items-end flex-wrap mb-3"
    >
      <gl-button
        variant="success"
        :loading="isImportingAnyRepo"
        :disabled="!hasProviderRepos"
        type="button"
        @click="importAll"
      >
        {{ importAllButtonText }}
      </gl-button>
      <slot name="actions"></slot>
      <form class="gl-ml-auto" novalidate @submit.prevent>
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
      v-if="isLoadingRepos"
      class="js-loading-button-icon import-projects-loading-icon"
      size="md"
    />
    <div
      v-else-if="hasProviderRepos || hasImportedProjects || hasIncompatibleRepos"
      class="table-responsive"
    >
      <table class="table import-table">
        <thead>
          <th class="import-jobs-from-col">{{ fromHeaderText }}</th>
          <th class="import-jobs-to-col">{{ __('To GitLab') }}</th>
          <th class="import-jobs-status-col">{{ __('Status') }}</th>
          <th class="import-jobs-cta-col"></th>
        </thead>
        <tbody>
          <imported-project-table-row
            v-for="project in importedProjects"
            :key="project.id"
            :project="project"
          />
          <provider-repo-table-row v-for="repo in providerRepos" :key="repo.id" :repo="repo" />
          <incompatible-repo-table-row
            v-for="repo in incompatibleRepos"
            :key="repo.id"
            :repo="repo"
          />
        </tbody>
      </table>
    </div>
    <div v-else class="text-center">
      <strong>{{ emptyStateText }}</strong>
    </div>
  </div>
</template>
