<script>
import { GlAlert, GlBadge, GlKeysetPagination, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import { MAX_LIST_COUNT } from '../constants';
import getStatesQuery from '../graphql/queries/get_states.query.graphql';
import EmptyState from './empty_state.vue';
import StatesTable from './states_table.vue';

export default {
  apollo: {
    states: {
      query: getStatesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          ...this.cursor,
        };
      },
      update: (data) => data,
      error() {
        this.states = null;
      },
    },
  },
  components: {
    EmptyState,
    GlAlert,
    GlBadge,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTab,
    GlTabs,
    StatesTable,
  },
  props: {
    emptyStateImage: {
      required: true,
      type: String,
    },
    projectPath: {
      required: true,
      type: String,
    },
    terraformAdmin: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      cursor: {
        first: MAX_LIST_COUNT,
        after: null,
        last: null,
        before: null,
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.states.loading;
    },
    pageInfo() {
      return this.states?.project?.terraformStates?.pageInfo || {};
    },
    showPagination() {
      return this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage;
    },
    statesCount() {
      return this.states?.project?.terraformStates?.count;
    },
    statesList() {
      return this.states?.project?.terraformStates?.nodes;
    },
  },
  methods: {
    nextPage(item) {
      this.cursor = {
        first: MAX_LIST_COUNT,
        after: item,
        last: null,
        before: null,
      };
    },
    prevPage(item) {
      this.cursor = {
        first: null,
        after: null,
        last: MAX_LIST_COUNT,
        before: item,
      };
    },
  },
};
</script>

<template>
  <section>
    <gl-tabs>
      <gl-tab>
        <template #title>
          <p class="gl-m-0">
            {{ s__('Terraform|States') }}
            <gl-badge v-if="statesCount">{{ statesCount }}</gl-badge>
          </p>
        </template>

        <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-3" />

        <div v-else-if="statesList">
          <div v-if="statesCount">
            <states-table :states="statesList" :terraform-admin="terraformAdmin" />

            <div v-if="showPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
              <gl-keyset-pagination v-bind="pageInfo" @prev="prevPage" @next="nextPage" />
            </div>
          </div>

          <empty-state v-else :image="emptyStateImage" />
        </div>

        <gl-alert v-else variant="danger" :dismissible="false">
          {{ s__('Terraform|An error occurred while loading your Terraform States') }}
        </gl-alert>
      </gl-tab>
    </gl-tabs>
  </section>
</template>
