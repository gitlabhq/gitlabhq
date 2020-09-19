<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlButton, GlLoadingIcon, GlIntersectionObserver, GlModal } from '@gitlab/ui';
import { n__, __, sprintf } from '~/locale';
import ProviderRepoTableRow from './provider_repo_table_row.vue';

export default {
  name: 'ImportProjectsTable',
  components: {
    ProviderRepoTableRow,
    GlLoadingIcon,
    GlButton,
    GlModal,
    GlIntersectionObserver,
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
    ...mapState(['filter', 'repositories', 'namespaces', 'defaultTargetNamespace']),
    ...mapGetters([
      'isLoading',
      'isImportingAnyRepo',
      'hasImportableRepos',
      'hasIncompatibleRepos',
      'importAllCount',
    ]),

    pagePaginationStateKey() {
      return `${this.filter}-${this.repositories.length}`;
    },

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
        ? n__(
            'Import %d compatible repository',
            'Import %d compatible repositories',
            this.importAllCount,
          )
        : n__('Import %d repository', 'Import %d repositories', this.importAllCount);
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
    this.fetchJobs();

    if (!this.paginatable) {
      this.fetchRepos();
    }
  },

  beforeDestroy() {
    this.stopJobsPolling();
    this.clearJobsEtagPoll();
  },

  methods: {
    ...mapActions([
      'fetchRepos',
      'fetchJobs',
      'fetchNamespaces',
      'stopJobsPolling',
      'clearJobsEtagPoll',
      'setFilter',
      'importAll',
    ]),
  },
};
</script>

<template>
  <div>
    <p class="light text-nowrap mt-2">
      {{ s__('ImportProjects|Select the repositories you want to import') }}
    </p>
    <template v-if="hasIncompatibleRepos">
      <slot name="incompatible-repos-warning"></slot>
    </template>
    <div class="d-flex justify-content-between align-items-end flex-wrap mb-3">
      <gl-button
        variant="success"
        :loading="isImportingAnyRepo"
        :disabled="!hasImportableRepos"
        type="button"
        @click="$refs.importAllModal.show()"
        >{{ importAllButtonText }}</gl-button
      >
      <gl-modal
        ref="importAllModal"
        modal-id="import-all-modal"
        :title="s__('ImportProjects|Import repositories')"
        :ok-title="__('Import')"
        @ok="importAll"
      >
        {{
          n__(
            'Are you sure you want to import %d repository?',
            'Are you sure you want to import %d repositories?',
            importAllCount,
          )
        }}
      </gl-modal>

      <slot name="actions"></slot>
      <form v-if="filterable" class="gl-ml-auto" novalidate @submit.prevent>
        <input
          data-qa-selector="githubish_import_filter_field"
          class="form-control"
          name="filter"
          :placeholder="__('Filter your repositories by name')"
          autofocus
          size="40"
          @keyup.enter="setFilter($event.target.value)"
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
    <gl-intersection-observer
      v-if="paginatable"
      :key="pagePaginationStateKey"
      @appear="fetchRepos"
    />
    <gl-loading-icon
      v-if="isLoading"
      class="js-loading-button-icon import-projects-loading-icon"
      size="md"
    />

    <div v-if="!isLoading && repositories.length === 0" class="text-center">
      <strong>{{ emptyStateText }}</strong>
    </div>
  </div>
</template>
