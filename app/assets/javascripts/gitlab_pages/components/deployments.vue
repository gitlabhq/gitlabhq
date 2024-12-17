<script>
import { GlToggle, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import getProjectPagesDeployments from '../queries/get_project_pages_deployments.graphql';
import PagesDeployment from './deployment.vue';
import LoadMoreDeployments from './load_more_deployments.vue';

export default {
  name: 'PagesDeployments',
  components: { LoadMoreDeployments, PagesDeployment, GlToggle, GlLoadingIcon, GlAlert },
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
    hasMultipleDeployments() {
      return (
        this.primaryDeployments?.nodes.length > 1 ||
        (this.primaryDeployments?.nodes.length && this.parallelDeployments?.nodes.length > 0)
      );
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
    toggleShowInactive() {
      this.showInactive = !this.showInactive;
    },
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
  <div>
    <gl-alert
      v-for="(message, id) in alerts"
      :key="id"
      variant="danger"
      class="gl-mb-4"
      sticky
      data-testid="alert"
      @dismiss="dismissAlert(id)"
    >
      {{ message }}
    </gl-alert>
    <div class="gl-mb-4 gl-flex gl-flex-col gl-justify-between md:gl-mb-0 md:gl-flex-row">
      <h2 class="gl-text-h2">
        {{ $options.i18n.title }}
      </h2>
      <span>
        <gl-toggle
          v-model="showInactive"
          :label="$options.i18n.showInactiveLabel"
          label-position="left"
          data-testid="show-inactive-toggle"
        />
      </span>
    </div>
    <div
      v-if="loadedPrimaryDeploymentsCount > 0"
      class="gl-flex gl-flex-col gl-gap-4"
      data-testid="primary-deployment-list"
    >
      <pages-deployment
        v-for="node in primaryDeployments.nodes"
        :key="node.id"
        :deployment="node"
        class="gl-mb-5"
        :query="$apollo.queries.primaryDeployments"
        data-testid="primary-deployment"
        @error="onChildError"
      />
      <load-more-deployments
        v-if="primaryDeployments && primaryDeployments.pageInfo.hasNextPage"
        :total-deployment-count="primaryDeploymentsNotLoaded"
        :loading="$apollo.queries.primaryDeployments.loading"
        class="gl-mt-3"
        data-testid="load-more-primary-deployments"
        @load-more="fetchMorePrimaryDeployments"
      />
    </div>
    <div v-if="loadedParallelDeploymentsCount > 0" data-testid="parallel-deployment-list">
      <h3 class="gl-heading-3">{{ $options.i18n.parallelDeploymentsTitle }}</h3>
      <div class="gl-flex gl-flex-col gl-gap-4">
        <pages-deployment
          v-for="node in parallelDeployments.nodes"
          :key="node.id"
          :deployment="node"
          :query="$apollo.queries.parallelDeployments"
          data-testid="parallel-deployment"
          @error="onChildError"
        />
      </div>
      <load-more-deployments
        v-if="parallelDeployments && parallelDeployments.pageInfo.hasNextPage"
        :total-deployment-count="parallelDeploymentsNotLoaded"
        :loading="$apollo.queries.parallelDeployments.loading"
        class="gl-mt-3"
        data-testid="load-more-parallel-deployments"
        @load-more="fetchMoreParallelDeployments"
      />
    </div>
    <div v-if="!primaryDeployments && !parallelDeployments && $apollo.loading">
      <gl-loading-icon size="md" />
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
