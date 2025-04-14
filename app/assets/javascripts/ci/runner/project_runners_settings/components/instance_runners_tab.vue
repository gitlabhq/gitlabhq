<script>
import { GlBadge, GlTab } from '@gitlab/ui';
import { I18N_FETCH_ERROR } from '~/ci/runner/constants';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import allRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners.query.graphql';
import RunnerName from '~/ci/runner/components/runner_name.vue';

export default {
  components: {
    GlBadge,
    GlTab,
    RunnerName,
  },
  data() {
    return {
      runners: {
        items: [],
        pageInfo: {},
      },
    };
  },
  apollo: {
    runners: {
      query: allRunnersQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          type: 'INSTANCE_TYPE',
        };
      },
      update(data) {
        const { runners } = data;
        return {
          items: runners?.nodes || [],
          pageInfo: runners?.pageInfo || {},
        };
      },
      error() {
        createAlert({ message: I18N_FETCH_ERROR });
      },
    },
  },
  computed: {
    runnersItems() {
      return this.runners.items;
    },
    runnersItemCount() {
      return this.runnersItems.length;
    },
  },
};
</script>
<template>
  <gl-tab>
    <template #title>
      <div class="gl-flex gl-gap-2">
        {{ __('Instance') }}
        <gl-badge>{{ runnersItemCount }}</gl-badge>
      </div>
    </template>

    <ul>
      <li v-for="runner in runnersItems" :key="runner.key">
        <runner-name :key="runner.key" :runner="runner" />
      </li>
    </ul>
  </gl-tab>
</template>
