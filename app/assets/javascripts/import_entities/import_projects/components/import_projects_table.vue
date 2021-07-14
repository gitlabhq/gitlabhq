<script>
import { GlButton, GlLoadingIcon, GlIntersectionObserver, GlModal, GlFormInput } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
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
    GlFormInput,
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
      'importingRepoCount',
      'hasImportableRepos',
      'hasIncompatibleRepos',
      'importAllCount',
    ]),

    pagePaginationStateKey() {
      return `${this.filter}-${this.repositories.length}`;
    },

    availableNamespaces() {
      return this.namespaces.map(({ fullPath }) => fullPath);
    },

    importAllButtonText() {
      if (this.isImportingAnyRepo) {
        return n__('Importing %d repository', 'Importing %d repositories', this.importingRepoCount);
      }

      if (this.hasIncompatibleRepos)
        return n__(
          'Import %d compatible repository',
          'Import %d compatible repositories',
          this.importAllCount,
        );
      return n__('Import %d repository', 'Import %d repositories', this.importAllCount);
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
    <p class="gl-text-gray-900 gl-white-space-nowrap gl-mt-3">
      {{ s__('ImportProjects|Select the repositories you want to import') }}
    </p>
    <template v-if="hasIncompatibleRepos">
      <slot name="incompatible-repos-warning"></slot>
    </template>
    <div class="gl-display-flex gl-justify-content-space-between gl-flex-wrap gl-mb-5">
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
        <gl-form-input
          data-qa-selector="githubish_import_filter_field"
          name="filter"
          :placeholder="__('Filter your repositories by name')"
          autofocus
          size="lg"
          @keyup.enter="setFilter($event.target.value)"
        />
      </form>
    </div>
    <div v-if="repositories.length" class="gl-w-full">
      <table>
        <thead class="gl-border-0 gl-border-solid gl-border-t-1 gl-border-gray-100">
          <th class="import-jobs-from-col gl-p-4 gl-vertical-align-top gl-border-b-1">
            {{ fromHeaderText }}
          </th>
          <th class="import-jobs-to-col gl-p-4 gl-vertical-align-top gl-border-b-1">
            {{ __('To GitLab') }}
          </th>
          <th class="import-jobs-status-col gl-p-4 gl-vertical-align-top gl-border-b-1">
            {{ __('Status') }}
          </th>
          <th class="import-jobs-cta-col gl-p-4 gl-vertical-align-top gl-border-b-1"></th>
        </thead>
        <tbody>
          <template v-for="repo in repositories">
            <provider-repo-table-row
              :key="repo.importSource.providerLink"
              :repo="repo"
              :available-namespaces="availableNamespaces"
              :user-namespace="defaultTargetNamespace"
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
    <gl-loading-icon v-if="isLoading" class="gl-mt-7" size="md" />

    <div v-if="!isLoading && repositories.length === 0" class="gl-text-center">
      <strong>{{ emptyStateText }}</strong>
    </div>
  </div>
</template>
