<script>
import {
  GlButton,
  GlLoadingIcon,
  GlIntersectionObserver,
  GlModal,
  GlSearchBoxByClick,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { n__, __, sprintf } from '~/locale';

import ProviderRepoTableRow from './provider_repo_table_row.vue';
import AdvancedSettings from './advanced_settings.vue';

export default {
  name: 'ImportProjectsTable',
  components: {
    AdvancedSettings,
    ProviderRepoTableRow,
    GlLoadingIcon,
    GlButton,
    GlModal,
    GlIntersectionObserver,
    GlSearchBoxByClick,
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
    cancelable: {
      type: Boolean,
      required: false,
      default: false,
    },
    optionalStages: {
      type: Array,
      required: false,
      default: () => [],
    },
    isAdvancedSettingsPanelInitiallyExpanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  data() {
    return {
      optionalStagesSelection: Object.fromEntries(
        this.optionalStages.map(({ name, selected }) => [name, selected]),
      ),
    };
  },

  computed: {
    ...mapState(['filter', 'repositories', 'pageInfo', 'isLoadingRepos']),
    ...mapGetters([
      'isImportingAnyRepo',
      'importingRepoCount',
      'hasImportableRepos',
      'hasIncompatibleRepos',
      'importAllCount',
    ]),

    pagePaginationStateKey() {
      return `${this.filter}-${this.repositories.length}-${this.pageInfo.page}`;
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
    this.fetchJobs();
    this.fetchRepos();
  },

  beforeDestroy() {
    this.stopJobsPolling();
    this.clearJobsEtagPoll();
  },

  methods: {
    ...mapActions([
      'fetchRepos',
      'fetchJobs',
      'stopJobsPolling',
      'clearJobsEtagPoll',
      'setFilter',
      'importAll',
    ]),

    showImportAllModal() {
      this.$refs.importAllModal.show();
    },
  },
};
</script>

<template>
  <div>
    <p class="gl-mt-3 gl-whitespace-nowrap gl-text-default">
      {{ s__('ImportProjects|Select the repositories you want to import') }}
    </p>
    <template v-if="hasIncompatibleRepos">
      <slot name="incompatible-repos-warning"></slot>
    </template>
    <slot name="filter" v-bind="{ showImportAllModal, importAllButtonText }">
      <div class="gl-mb-5 gl-flex gl-flex-wrap gl-justify-between">
        <gl-button
          variant="confirm"
          :loading="isImportingAnyRepo"
          :disabled="!hasImportableRepos"
          type="button"
          @click="showImportAllModal"
          >{{ importAllButtonText }}</gl-button
        >

        <slot name="actions"></slot>
        <form v-if="filterable" class="gl-ml-auto" novalidate @submit.prevent>
          <gl-search-box-by-click
            name="filter"
            :placeholder="__('Filter by name')"
            autofocus
            @submit="setFilter({ filter: $event })"
            @clear="setFilter({ filter: '' })"
          />
        </form>
      </div>
    </slot>
    <advanced-settings
      v-if="optionalStages && optionalStages.length"
      v-model="optionalStagesSelection"
      :stages="optionalStages"
      :is-initially-expanded="isAdvancedSettingsPanelInitiallyExpanded"
      class="gl-mb-5"
    />
    <gl-modal
      ref="importAllModal"
      modal-id="import-all-modal"
      :title="s__('ImportProjects|Import repositories')"
      :ok-title="__('Import')"
      @ok="importAll({ optionalStages: optionalStagesSelection })"
    >
      {{
        n__(
          'Are you sure you want to import %d repository?',
          'Are you sure you want to import %d repositories?',
          importAllCount,
        )
      }}
    </gl-modal>
    <div v-if="repositories.length" class="gl-w-full">
      <table class="table gl-table">
        <thead>
          <tr>
            <th class="gl-w-1/2">
              {{ fromHeaderText }}
            </th>
            <th class="gl-w-1/2">
              {{ __('To GitLab') }}
            </th>
            <th>
              {{ __('Status') }}
            </th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <template v-for="repo in repositories">
            <provider-repo-table-row
              :key="repo.importSource.providerLink"
              :repo="repo"
              :optional-stages="optionalStagesSelection"
              :cancelable="cancelable"
            />
          </template>
        </tbody>
      </table>
    </div>
    <gl-intersection-observer
      v-if="!isLoadingRepos && paginatable && pageInfo.hasNextPage"
      :key="pagePaginationStateKey"
      @appear="fetchRepos"
    />
    <gl-loading-icon v-if="isLoadingRepos" class="gl-mt-7" size="lg" />

    <div v-if="!isLoadingRepos && repositories.length === 0" class="gl-text-center">
      <strong>{{ emptyStateText }}</strong>
    </div>
  </div>
</template>
