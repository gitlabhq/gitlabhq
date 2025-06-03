<script>
import { GlAlert, GlLink, GlTab, GlBadge, GlLoadingIcon } from '@gitlab/ui';
import { captureException } from '~/ci/runner/sentry_utils';
import { fetchPolicies } from '~/lib/graphql';

import { I18N_FETCH_ERROR } from '~/ci/runner/constants';
import projectRunnersQuery from '~/ci/runner/graphql/list/project_runners.query.graphql';
import RunnerList from '~/ci/runner/components/runner_list.vue';
import RunnerName from '~/ci/runner/components/runner_name.vue';
import RunnerActionsCell from '~/ci/runner/components/cells/runner_actions_cell.vue';
import RunnerPagination from '~/ci/runner/components/runner_pagination.vue';

import { getPaginationVariables } from '../../utils';

export default {
  name: 'RunnersTab',
  components: {
    GlAlert,
    GlLink,
    GlTab,
    GlBadge,
    GlLoadingIcon,
    RunnerList,
    RunnerName,
    RunnerActionsCell,
    RunnerPagination,
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
      pagination: {},
      runners: {
        count: null,
        items: [],
        pageInfo: {},
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
        const { edges = [], pageInfo = {}, count } = data?.project?.runners || {};
        const items = edges.map(({ node, webUrl, editUrl }) => ({ ...node, webUrl, editUrl }));

        return {
          count,
          items,
          pageInfo,
        };
      },
      error(error) {
        captureException({ error, component: this.$options.name });

        this.$emit('error', { error, message: I18N_FETCH_ERROR });
      },
    },
  },
  computed: {
    variables() {
      return {
        fullPath: this.projectFullPath,
        type: this.runnerType,
        ...getPaginationVariables(this.pagination),
      };
    },
    isLoading() {
      return Boolean(this.loading);
    },
    isEmpty() {
      return !this.runners.items?.length && !this.isLoading;
    },
  },
  methods: {
    onPaginationInput(value) {
      this.pagination = value;
    },

    // Component API
    // eslint-disable-next-line vue/no-unused-properties
    refresh() {
      this.$apollo.queries.runners.refresh();
    },
  },
};
</script>
<template>
  <gl-tab>
    <template #title>
      <div class="gl-flex gl-gap-2">
        {{ title }}
        <gl-loading-icon v-if="isLoading" size="sm" />
        <gl-badge v-else-if="runners.count">{{ runners.count }}</gl-badge>
      </div>
    </template>

    <div v-if="$scopedSlots.settings" class="gl-mx-5 gl-mb-5 gl-mt-3">
      <slot name="settings"></slot>
    </div>
    <div v-if="$scopedSlots.description" class="gl-mx-5 gl-mb-5">
      <gl-alert variant="tip" :dismissible="false">
        <slot name="description"></slot>
      </gl-alert>
    </div>
    <p v-if="isEmpty" data-testid="empty-message" class="gl-mx-5 gl-mb-5 gl-text-subtle">
      <slot name="empty"></slot>
    </p>
    <runner-list v-else :runners="runners.items" :loading="isLoading">
      <template #runner-name="{ runner }">
        <gl-link v-if="runner.webUrl" data-testid="runner-link" :href="runner.webUrl">
          <runner-name :runner="runner" />
        </gl-link>
        <runner-name v-else :runner="runner" />
      </template>
      <template #runner-actions-cell="{ runner }">
        <runner-actions-cell :runner="runner" size="small" :edit-url="runner.editUrl">
          <slot name="other-runner-actions" :runner="runner"></slot>
        </runner-actions-cell>
      </template>
    </runner-list>

    <runner-pagination
      class="gl-border-t gl-mb-3 gl-mt-5 gl-pt-5 gl-text-center"
      :disabled="isLoading"
      :page-info="runners.pageInfo"
      @input="onPaginationInput"
    />
  </gl-tab>
</template>
