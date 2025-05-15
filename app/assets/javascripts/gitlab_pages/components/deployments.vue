<script>
import { GlToggle, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import getProjectPagesDeployments from '../queries/get_project_pages_deployments.graphql';
import PagesDeployment from './deployment.vue';
import LoadMoreDeployments from './load_more_deployments.vue';

export default {
  name: 'PagesDeployments',
  components: {
    CrudComponent,
    LoadMoreDeployments,
    PagesDeployment,
    GlToggle,
    GlLoadingIcon,
    GlAlert,
  },
  inject: ['projectFullPath'],
  i18n: {
    title: s__('Pages|Deployments'),
    parallelDeploymentsTitle: s__('Pages|Parallel deployments'),
    noDeploymentsMessage: s__('Pages|No deployments yet'),
    loadErrorMessage: s__(
      'Pages|Some Pages deployments could not be loaded. Try reloading the page.',
    ),
    showInactiveLabel: s__('Pages|Show stopped deployments'),
  },
  data() {
    return {
      showInactive: false,
      requestBatchSize: 10,
      hasError: false,
      alerts: {},
      primaryDeployments: null,
      parallelDeployments: null,
    };
  },
  computed: {
    sharedQueryVariables() {
      return {
        active: this.showInactive ? undefined : true,
        fullPath: this.projectFullPath,
        first: this.requestBatchSize,
      };
    },
    primaryDeploymentsNotLoaded() {
      if (!this.primaryDeployments) return undefined;
      return this.primaryDeployments.count - this.primaryDeployments.nodes.length;
    },
    parallelDeploymentsNotLoaded() {
      if (!this.parallelDeployments) return 0;
      return this.parallelDeployments.count - this.parallelDeployments.nodes.length;
    },
    loadedPrimaryDeploymentsCount() {
      return this.primaryDeployments?.nodes.length || 0;
    },
    loadedParallelDeploymentsCount() {
      return this.parallelDeployments?.nodes.length || 0;
    },
  },
  apollo: {
    primaryDeployments: {
      query: getProjectPagesDeployments,
      variables() {
        return {
          ...this.sharedQueryVariables,
          versioned: false,
        };
      },
      update(data) {
        return data.project.pagesDeployments;
      },
      error() {
        this.hasError = true;
      },
    },
    parallelDeployments: {
      query: getProjectPagesDeployments,
      variables() {
        return {
          ...this.sharedQueryVariables,
          versioned: true,
        };
      },
      update(data) {
        return data.project.pagesDeployments;
      },
      error() {
        this.hasError = true;
      },
    },
  },
  methods: {
    fetchMorePrimaryDeployments() {
      this.$apollo.queries.primaryDeployments.fetchMore({
        variables: {
          after: this.primaryDeployments.pageInfo.endCursor,
        },
        updateQuery: this.fetchMoreUpdateResult,
      });
    },
    fetchMoreParallelDeployments() {
      this.$apollo.queries.parallelDeployments.fetchMore({
        variables: {
          after: this.parallelDeployments.pageInfo.endCursor,
        },
        updateQuery: this.fetchMoreUpdateResult,
      });
    },
    fetchMoreUpdateResult(previousResult, { fetchMoreResult }) {
      return {
        project: {
          ...previousResult.project,
          pagesDeployments: {
            ...fetchMoreResult.project.pagesDeployments,
            nodes: [
              /*
               * This weird presence check makes this method resilient against
               * empty previousResults, which *should* not happen, but who knows?
               * */
              ...(previousResult?.project?.pagesDeployments
                ? previousResult.project.pagesDeployments.nodes
                : []),
              ...fetchMoreResult.project.pagesDeployments.nodes,
            ],
            pageInfo: fetchMoreResult.project.pagesDeployments.pageInfo,
          },
        },
      };
    },
    onChildError({ id, message }) {
      this.alerts = {
        ...this.alerts,
        [id]: message,
      };
    },
    dismissAlert(id) {
      const copy = { ...this.alerts };
      delete copy[id];
      this.alerts = copy;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-5">
    <gl-alert
      v-for="(message, id) in alerts"
      :key="id"
      variant="danger"
      sticky
      data-testid="alert"
      @dismiss="dismissAlert(id)"
    >
      {{ message }}
    </gl-alert>

    <crud-component
      v-if="loadedPrimaryDeploymentsCount > 0"
      :title="$options.i18n.title"
      data-testid="primary-deployment-list"
    >
      <template #actions>
        <gl-toggle
          v-model="showInactive"
          :label="$options.i18n.showInactiveLabel"
          label-position="left"
          data-testid="show-inactive-toggle"
        />
      </template>

      <ul class="content-list">
        <pages-deployment
          v-for="node in primaryDeployments.nodes"
          :key="node.id"
          :deployment="node"
          :query="$apollo.queries.primaryDeployments"
          data-testid="primary-deployment"
          @error="onChildError"
        />
      </ul>

      <template v-if="primaryDeployments && primaryDeployments.pageInfo.hasNextPage" #pagination>
        <load-more-deployments
          :total-deployment-count="primaryDeploymentsNotLoaded"
          :loading="$apollo.queries.primaryDeployments.loading"
          data-testid="load-more-primary-deployments"
          @load-more="fetchMorePrimaryDeployments"
        />
      </template>
    </crud-component>

    <crud-component
      v-if="loadedParallelDeploymentsCount > 0"
      :title="$options.i18n.parallelDeploymentsTitle"
      data-testid="parallel-deployment-list"
    >
      <ul class="content-list">
        <pages-deployment
          v-for="node in parallelDeployments.nodes"
          :key="node.id"
          :deployment="node"
          :query="$apollo.queries.parallelDeployments"
          data-testid="parallel-deployment"
          @error="onChildError"
        />
      </ul>

      <template v-if="parallelDeployments && parallelDeployments.pageInfo.hasNextPage" #pagination>
        <load-more-deployments
          :total-deployment-count="parallelDeploymentsNotLoaded"
          :loading="$apollo.queries.parallelDeployments.loading"
          data-testid="load-more-parallel-deployments"
          @load-more="fetchMoreParallelDeployments"
        />
      </template>
    </crud-component>

    <div v-if="!primaryDeployments && !parallelDeployments && $apollo.loading">
      <gl-loading-icon size="sm" />
    </div>
    <div
      v-else-if="!loadedPrimaryDeploymentsCount && !loadedParallelDeploymentsCount"
      class="gl-text-center gl-text-subtle"
    >
      {{ $options.i18n.noDeploymentsMessage }}
    </div>
    <gl-alert v-if="hasError" variant="danger" :dismissible="false">
      {{ $options.i18n.loadErrorMessage }}
    </gl-alert>
  </div>
</template>
