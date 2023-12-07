<script>
import { GlSkeletonLoader, GlTabs, GlTab, GlBadge } from '@gitlab/ui';
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
  },
  data() {
    return {
      environmentToDelete: {},
      environmentToRollback: {},
      environmentToStop: {},
      environmentToChangeCanary: {},
      weight: 0,
    };
  },
  apollo: {
    folder: {
      query: folderQuery,
      variables() {
        return {
          environment: this.environmentQueryData,
          scope: this.scope,
          search: '',
          perPage: 10,
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
  ENVIRONMENTS_SCOPE,
};
</script>
<template>
  <div>
    <delete-environment-modal :environment="environmentToDelete" graphql />
    <stop-environment-modal :environment="environmentToStop" graphql />
    <confirm-rollback-modal :environment="environmentToRollback" graphql />
    <canary-update-modal :environment="environmentToChangeCanary" :weight="weight" />
    <h4 class="gl-font-weight-normal" data-testid="folder-name">
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
          <gl-badge size="sm" class="gl-tab-counter-badge">
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
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ stoppedCount }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <div v-if="isLoading">
      <div
        v-for="n in 3"
        :key="`skeleton-box-${n}`"
        class="gl-border-gray-100 gl-border-t-solid gl-border-1 gl-py-5 gl-md-pl-7"
      >
        <gl-skeleton-loader :lines="2" />
      </div>
    </div>
    <div v-else>
      <environment-item
        v-for="environment in environments"
        :id="environment.name"
        :key="environment.name"
        :environment="environment"
        class="gl-border-gray-100 gl-border-t-solid gl-border-1 gl-pt-3"
        in-folder
      />
    </div>
  </div>
</template>
