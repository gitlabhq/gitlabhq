<script>
/**
 * Render environments table.
 */
import { GlLoadingIcon } from '@gitlab/ui';
import _ from 'underscore';
import environmentTableMixin from 'ee_else_ce/environments/mixins/environments_table_mixin';
import EnvironmentItem from './environment_item.vue';

export default {
  components: {
    EnvironmentItem,
    GlLoadingIcon,
    DeployBoard: () => import('ee_component/environments/components/deploy_board_component.vue'),
    CanaryDeploymentCallout: () =>
      import('ee_component/environments/components/canary_deployment_callout.vue'),
  },
  mixins: [environmentTableMixin],
  props: {
    environments: {
      type: Array,
      required: true,
      default: () => [],
    },
    deployBoardsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    sortedEnvironments() {
      return this.sortEnvironments(this.environments).map(env =>
        this.shouldRenderFolderContent(env)
          ? { ...env, children: this.sortEnvironments(env.children) }
          : env,
      );
    },
  },
  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
    shouldRenderFolderContent(env) {
      return env.isFolder && env.isOpen && env.children && env.children.length > 0;
    },
    sortEnvironments(environments) {
      /*
       * The sorting algorithm should sort in the following priorities:
       *
       * 1. folders first,
       * 2. last updated descending,
       * 3. by name ascending,
       *
       * the sorting algorithm must:
       *
       * 1. Sort by name ascending,
       * 2. Reverse (sort by name descending),
       * 3. Sort by last deployment ascending,
       * 4. Reverse (last deployment descending, name ascending),
       * 5. Put folders first.
       */
      return _.chain(environments)
        .sortBy(env => (env.isFolder ? env.folderName : env.name))
        .reverse()
        .sortBy(env => (env.last_deployment ? env.last_deployment.created_at : '0000'))
        .reverse()
        .sortBy(env => (env.isFolder ? -1 : 1))
        .value();
    },
  },
};
</script>
<template>
  <div class="ci-table" role="grid">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-15 environments-name" role="columnheader">
        {{ s__('Environments|Environment') }}
      </div>
      <div class="table-section section-10 environments-deploy" role="columnheader">
        {{ s__('Environments|Deployment') }}
      </div>
      <div class="table-section section-15 environments-build" role="columnheader">
        {{ s__('Environments|Job') }}
      </div>
      <div class="table-section section-20 environments-commit" role="columnheader">
        {{ s__('Environments|Commit') }}
      </div>
      <div class="table-section section-10 environments-date" role="columnheader">
        {{ s__('Environments|Updated') }}
      </div>
    </div>
    <template v-for="(model, i) in sortedEnvironments" :model="model">
      <div
        is="environment-item"
        :key="`environment-item-${i}`"
        :model="model"
        :can-read-environment="canReadEnvironment"
      />

      <div
        v-if="shouldRenderDeployBoard(model)"
        :key="`deploy-board-row-${i}`"
        class="js-deploy-board-row"
      >
        <div class="deploy-board-container">
          <deploy-board
            :deploy-board-data="model.deployBoardData"
            :deploy-boards-help-path="deployBoardsHelpPath"
            :is-loading="model.isLoadingDeployBoard"
            :is-empty="model.isEmptyDeployBoard"
            :has-legacy-app-label="model.hasLegacyAppLabel"
            :logs-path="model.logs_path"
          />
        </div>
      </div>

      <template v-if="shouldRenderFolderContent(model)">
        <div v-if="model.isLoadingFolderContent" :key="`loading-item-${i}`">
          <gl-loading-icon :size="2" class="prepend-top-16" />
        </div>

        <template v-else>
          <div
            is="environment-item"
            v-for="(children, index) in model.children"
            :key="`env-item-${i}-${index}`"
            :model="children"
            :can-read-environment="canReadEnvironment"
          />

          <div :key="`sub-div-${i}`">
            <div class="text-center prepend-top-10">
              <a :href="folderUrl(model)" class="btn btn-default">
                {{ s__('Environments|Show all') }}
              </a>
            </div>
          </div>
        </template>
      </template>

      <template v-if="shouldShowCanaryCallout(model)">
        <canary-deployment-callout
          :key="`canary-promo-${i}`"
          :canary-deployment-feature-id="canaryDeploymentFeatureId"
          :user-callouts-path="userCalloutsPath"
          :lock-promotion-svg-path="lockPromotionSvgPath"
          :help-canary-deployments-path="helpCanaryDeploymentsPath"
          :data-js-canary-promo-key="i"
        />
      </template>
    </template>
  </div>
</template>
