<script>
import { GlSkeletonLoader, GlTabs, GlTab, GlBadge, GlPagination } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import folderQuery from '../graphql/queries/folder.query.graphql';
import environmentToDeleteQuery from '../graphql/queries/environment_to_delete.query.graphql';
import environmentToRollbackQuery from '../graphql/queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from '../graphql/queries/environment_to_stop.query.graphql';
import environmentToChangeCanaryQuery from '../graphql/queries/environment_to_change_canary.query.graphql';
import EnvironmentItem from '../components/new_environment_item.vue';
import StopEnvironmentModal from '../components/stop_environment_modal.vue';
import ConfirmRollbackModal from '../components/confirm_rollback_modal.vue';
import DeleteEnvironmentModal from '../components/delete_environment_modal.vue';
import CanaryUpdateModal from '../components/canary_update_modal.vue';
import { ENVIRONMENTS_SCOPE } from '../constants';

export default {
  components: {
    GlPagination,
    GlBadge,
    GlTabs,
    GlTab,
    GlSkeletonLoader,
    EnvironmentItem,
    StopEnvironmentModal,
    ConfirmRollbackModal,
    DeleteEnvironmentModal,
    CanaryUpdateModal,
  },
  props: {
    folderName: {
      type: String,
      required: true,
    },
    folderPath: {
      type: String,
      required: true,
    },
    scope: {
      type: String,
      required: true,
      default: ENVIRONMENTS_SCOPE.ACTIVE,
    },
    page: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      environmentToDelete: {},
      environmentToRollback: {},
      environmentToStop: {},
      environmentToChangeCanary: {},
      weight: 0,
      lastRowCount: 3,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    folder: {
      query: folderQuery,
      variables() {
        return {
          environment: this.environmentQueryData,
          scope: this.scope,
          search: '',
          perPage: this.$options.perPage,
          page: this.page,
        };
      },
      pollInterval: 3000,
    },
    environmentToDelete: {
      query: environmentToDeleteQuery,
    },
    environmentToRollback: {
      query: environmentToRollbackQuery,
    },
    environmentToStop: {
      query: environmentToStopQuery,
    },
    environmentToChangeCanary: {
      query: environmentToChangeCanaryQuery,
    },
    weight: {
      query: environmentToChangeCanaryQuery,
    },
  },
  computed: {
    environmentQueryData() {
      return { folderPath: this.folderPath };
    },
    environments() {
      return this.folder?.environments;
    },
    isLoading() {
      return this.$apollo.queries.folder.loading;
    },
    activeCount() {
      return this.folder?.activeCount ?? '-';
    },
    stoppedCount() {
      return this.folder?.stoppedCount ?? '-';
    },
    activeTab() {
      return this.scope === ENVIRONMENTS_SCOPE.ACTIVE ? 0 : 1;
    },
    totalItems() {
      const environmentsCount =
        this.scope === ENVIRONMENTS_SCOPE.ACTIVE
          ? this.folder?.activeCount
          : this.folder?.stoppedCount;
      return Number(environmentsCount);
    },
    totalPages() {
      return Math.ceil(this.totalItems / this.$options.perPage);
    },
    hasNextPage() {
      return this.page !== this.totalPages;
    },
    hasPreviousPage() {
      return this.page > 1;
    },
    pageNumber: {
      get() {
        return this.page;
      },
      set(newPageNumber) {
        if (newPageNumber !== this.page) {
          const query = { ...this.$route.query, page: newPageNumber };
          this.$router.push({ query });
        }
      },
    },
  },
  watch: {
    environments(newEnvironments) {
      if (newEnvironments?.length) {
        this.lastRowCount = newEnvironments.length;
      }

      // When we load a page, if there's next and/or previous pages existing,
      // we'll load their data as well to improve percepted performance.
      // The page data is cached by apollo client and is immediately accessible
      // and won't trigger additional requests
      if (this.hasNextPage) {
        this.$apollo.query({
          query: folderQuery,
          variables: {
            environment: this.environmentQueryData,
            scope: this.scope,
            search: '',
            perPage: this.$options.perPage,
            page: this.page + 1,
          },
        });
      }

      if (this.hasPreviousPage) {
        this.$apollo.query({
          query: folderQuery,
          variables: {
            environment: this.environmentQueryData,
            scope: this.scope,
            search: '',
            perPage: this.$options.perPage,
            page: this.page - 1,
          },
        });
      }
    },
  },
  methods: {
    setScope(scope) {
      if (scope !== this.scope) {
        this.$router.push({ query: { scope } });
      }
    },
  },
  i18n: {
    pageTitle: s__('Environments|Environments'),
    active: __('Active'),
    stopped: __('Stopped'),
  },
  perPage: 20,
  ENVIRONMENTS_SCOPE,
};
</script>
<template>
  <div>
    <delete-environment-modal :environment="environmentToDelete" graphql />
    <stop-environment-modal :environment="environmentToStop" graphql />
    <confirm-rollback-modal :environment="environmentToRollback" graphql />
    <canary-update-modal :environment="environmentToChangeCanary" :weight="weight" />
    <h4 class="gl-font-normal" data-testid="folder-name">
      {{ $options.i18n.pageTitle }} /
      <b>{{ folderName }}</b>
    </h4>
    <gl-tabs :value="activeTab" query-param-name="scope">
      <gl-tab
        :query-param-value="$options.ENVIRONMENTS_SCOPE.ACTIVE"
        @click="setScope($options.ENVIRONMENTS_SCOPE.ACTIVE)"
      >
        <template #title>
          <span>{{ $options.i18n.active }}</span>
          <gl-badge class="gl-tab-counter-badge">
            {{ activeCount }}
          </gl-badge>
        </template>
      </gl-tab>
      <gl-tab
        :query-param-value="$options.ENVIRONMENTS_SCOPE.STOPPED"
        @click="setScope($options.ENVIRONMENTS_SCOPE.STOPPED)"
      >
        <template #title>
          <span>{{ $options.i18n.stopped }}</span>
          <gl-badge class="gl-tab-counter-badge">
            {{ stoppedCount }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <div v-if="isLoading">
      <div
        v-for="n in lastRowCount"
        :key="`skeleton-box-${n}`"
        class="gl-border-1 gl-border-default gl-py-5 gl-border-t-solid md:gl-pl-7"
      >
        <gl-skeleton-loader :lines="2" />
      </div>
    </div>
    <div v-else>
      <!--
        We assign each element's key as index intentionally here.
        Creation and destruction of "environments-item" component is quite taxing and leads
        to noticeable blocking rendering times for lists of more than 10 items.
        By assigning indexes we avoid destroying and re-creating the components when page changes,
        thus getting a much better performance.
        Correct component state is ensured by deep data-binding of "environment" prop
      -->
      <environment-item
        v-for="(environment, index) in environments"
        :id="environment.name"
        :key="index"
        :environment="environment"
        class="gl-border-1 gl-border-default gl-pt-3 gl-border-t-solid"
        in-folder
      />
    </div>
    <gl-pagination
      v-model="pageNumber"
      :per-page="$options.perPage"
      :total-items="totalItems"
      align="center"
    />
  </div>
</template>
