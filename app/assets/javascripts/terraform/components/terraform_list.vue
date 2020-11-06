<script>
import { GlAlert, GlBadge, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
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
        };
      },
      update: data => {
        return {
          count: data?.project?.terraformStates?.count,
          list: data?.project?.terraformStates?.nodes,
        };
      },
      error() {
        this.states = null;
      },
    },
  },
  components: {
    EmptyState,
    GlAlert,
    GlBadge,
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
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.states.loading;
    },
    statesCount() {
      return this.states?.count;
    },
    statesList() {
      return this.states?.list;
    },
  },
};
</script>

<template>
  <section>
    <gl-tabs>
      <gl-tab>
        <template slot="title">
          <p class="gl-m-0">
            {{ s__('Terraform|States') }}
            <gl-badge v-if="statesCount">{{ statesCount }}</gl-badge>
          </p>
        </template>

        <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-3" />

        <div v-else-if="statesList">
          <states-table v-if="statesCount" :states="statesList" />

          <empty-state v-else :image="emptyStateImage" />
        </div>

        <gl-alert v-else variant="danger" :dismissible="false">
          {{ s__('Terraform|An error occurred while loading your Terraform States') }}
        </gl-alert>
      </gl-tab>
    </gl-tabs>
  </section>
</template>
