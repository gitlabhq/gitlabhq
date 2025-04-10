<script>
import { GlBadge, GlTab } from '@gitlab/ui';
import { __ } from '~/locale';
import { I18N_FETCH_ERROR } from '~/ci/runner/constants';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import groupRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners.query.graphql';

import RunnerName from '~/ci/runner/components/runner_name.vue';

export const QUERY_TYPES = {
  project: 'PROJECT_TYPE',
  group: 'GROUP_TYPE',
};

export default {
  components: {
    GlBadge,
    GlTab,
    RunnerName,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: __('Project'),
    },
    type: {
      type: String,
      required: false,
      default: 'project',
    },
    groupFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      runners: {
        items: [],
        urlsById: {},
        pageInfo: {},
      },
    };
  },
  apollo: {
    runners: {
      query: groupRunnersQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          type: QUERY_TYPES[this.type],
          groupFullPath: this.groupFullPath,
        };
      },
      update(data) {
        const { edges = [], pageInfo = {} } = data?.group?.runners || {};
        const items = edges.map(({ node }) => node);
        return { items, pageInfo };
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
    runnersItemsCount() {
      return this.runnersItems.length;
    },
  },
};
</script>
<template>
  <gl-tab>
    <template #title>
      <div class="gl-flex gl-gap-2">
        {{ title }}
        <gl-badge>{{ runnersItemsCount }}</gl-badge>
      </div>
    </template>

    <ul>
      <li v-for="runner in runnersItems" :key="runner.key">
        <runner-name :key="runner.key" :runner="runner" />
      </li>
    </ul>
  </gl-tab>
</template>
