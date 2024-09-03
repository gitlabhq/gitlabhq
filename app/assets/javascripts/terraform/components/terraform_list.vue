<script>
import { GlAlert, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { MAX_LIST_COUNT } from '../constants';
import getStatesQuery from '../graphql/queries/get_states.query.graphql';
import EmptyState from './empty_state.vue';
import StatesTable from './states_table.vue';

export default {
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    GlKeysetPagination,
    GlLoadingIcon,
    StatesTable,
    CrudComponent,
  },
  inject: ['projectPath'],
  props: {
    emptyStateImage: {
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
    <crud-component
      :title="s__('Terraform|Terraform states')"
      icon="terraform"
      :count="statesCount"
      class="gl-mt-5"
    >
      <gl-loading-icon v-if="isLoading" size="md" />
      <div v-else-if="statesList">
        <div v-if="statesCount">
          <states-table :states="statesList" :terraform-admin="terraformAdmin" />
        </div>
        <empty-state v-else :image="emptyStateImage" />
      </div>
      <gl-alert v-else variant="danger" :dismissible="false">
        {{ s__('Terraform|An error occurred while loading your Terraform States') }}
      </gl-alert>
      <template v-if="showPagination" #pagination>
        <gl-keyset-pagination v-bind="pageInfo" @prev="prevPage" @next="nextPage" />
      </template>
    </crud-component>
  </section>
</template>
