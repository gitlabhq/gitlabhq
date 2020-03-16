<script>
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { __, sprintf } from '~/locale';
import ImportedProjectTableRow from './imported_project_table_row.vue';
import ProviderRepoTableRow from './provider_repo_table_row.vue';
import eventHub from '../event_hub';

const reposFetchThrottleDelay = 1000;

export default {
  name: 'ImportProjectsTable',
  components: {
    ImportedProjectTableRow,
    ProviderRepoTableRow,
    LoadingButton,
    GlLoadingIcon,
  },
  props: {
    providerTitle: {
      type: String,
      required: true,
    },
  },

  computed: {
    ...mapState(['importedProjects', 'providerRepos', 'isLoadingRepos', 'filter']),
    ...mapGetters(['isImportingAnyRepo', 'hasProviderRepos', 'hasImportedProjects']),

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
      eventHub.$off('importAll');
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

    <div class="d-flex justify-content-between align-items-end flex-wrap mb-3">
      <loading-button
        container-class="btn btn-success js-import-all"
        :loading="isImportingAnyRepo"
        :label="__('Import all repositories')"
        :disabled="!hasProviderRepos"
        type="button"
        @click="importAll"
      />
      <form novalidate @submit.prevent>
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
    <div v-else-if="hasProviderRepos || hasImportedProjects" class="table-responsive">
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
        </tbody>
      </table>
    </div>
    <div v-else class="text-center">
      <strong>{{ emptyStateText }}</strong>
    </div>
  </div>
</template>
