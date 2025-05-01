<script>
import { GlLink, GlTab, GlBadge } from '@gitlab/ui';
import RunnerList from '~/ci/runner/components/runner_list.vue';
import RunnerName from '~/ci/runner/components/runner_name.vue';
import { fetchPolicies } from '~/lib/graphql';
import projectRunnersQuery from '~/ci/runner/graphql/list/project_runners.query.graphql';

export default {
  name: 'RunnersTab',
  components: {
    GlLink,
    GlTab,
    GlBadge,
    RunnerList,
    RunnerName,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    runnerType: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],
  data() {
    return {
      loading: 0, // Initialized to 0 as this is used by a "loadingKey". See https://apollo.vuejs.org/api/smart-query.html#options
      runners: {
        count: null,
        items: [],
      },
    };
  },
  apollo: {
    runners: {
      query: projectRunnersQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      loadingKey: 'loading',
      variables() {
        return this.variables;
      },
      update(data) {
        const { edges = [], count } = data?.project?.runners || {};
        const items = edges.map(({ node, webUrl }) => ({ ...node, webUrl }));

        return {
          count,
          items,
        };
      },
      error(error) {
        this.$emit('error', error);
      },
    },
  },
  computed: {
    variables() {
      return {
        fullPath: this.projectFullPath,
        type: this.runnerType,
      };
    },
    isLoading() {
      return Boolean(this.loading);
    },
    isEmpty() {
      return !this.runners.items?.length && !this.loading;
    },
  },
};
</script>
<template>
  <gl-tab>
    <template #title>
      <div class="gl-flex gl-gap-2">
        {{ title }}
        <gl-badge v-if="runners.count !== null">{{ runners.count }}</gl-badge>
      </div>
    </template>

    <p v-if="isEmpty" data-testid="empty-message" class="gl-px-5 gl-pt-5 gl-text-subtle">
      <slot name="empty"></slot>
    </p>
    <runner-list v-else :runners="runners.items" :loading="isLoading">
      <template #runner-name="{ runner }">
        <gl-link data-testid="runner-link" :href="runner.webUrl">
          <runner-name :runner="runner" />
        </gl-link>
      </template>
    </runner-list>
  </gl-tab>
</template>
