<script>
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import ProviderRepoTableRow from './provider_repo_table_row.vue';
import PageQueryParamSync from './page_query_param_sync.vue';

const reposFetchThrottleDelay = 1000;

export default {
  name: 'ImportProjectsTable',
  components: {
    ProviderRepoTableRow,
    PageQueryParamSync,
    GlLoadingIcon,
    GlButton,
    PaginationLinks,
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
    paginatable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    ...mapState(['filter', 'repositories', 'namespaces', 'defaultTargetNamespace', 'pageInfo']),
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
      'setPage',
    ]),

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
    <page-query-param-sync :page="pageInfo.page" @popstate="setPage" />

    <p class="light text-nowrap mt-2">
      {{ s__('ImportProjects|Select the projects you want to import') }}
    </p>
    <template v-if="hasIncompatibleRepos">
      <slot name="incompatible-repos-warning"></slot>
    </template>
    <gl-loading-icon
      v-if="isLoading"
      class="js-loading-button-icon import-projects-loading-icon"
      size="md"
    />
    <template v-if="!isLoading">
      <div class="d-flex justify-content-between align-items-end flex-wrap mb-3">
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
      <div v-if="repositories.length" class="table-responsive">
        <table class="table import-table">
          <thead>
            <th class="import-jobs-from-col">{{ fromHeaderText }}</th>
            <th class="import-jobs-to-col">{{ __('To GitLab') }}</th>
            <th class="import-jobs-status-col">{{ __('Status') }}</th>
            <th class="import-jobs-cta-col"></th>
          </thead>
          <tbody>
            <template v-for="repo in repositories">
              <provider-repo-table-row
                :key="repo.importSource.providerLink"
                :repo="repo"
                :available-namespaces="availableNamespaces"
              />
            </template>
          </tbody>
        </table>
      </div>
      <div v-else class="text-center">
        <strong>{{ emptyStateText }}</strong>
      </div>
      <pagination-links
        v-if="paginatable"
        align="center"
        class="gl-mt-3"
        :page-info="pageInfo"
        :prev-page="pageInfo.page - 1"
        :next-page="repositories.length && pageInfo.page + 1"
        :change="setPage"
      />
    </template>
  </div>
</template>
