<script>
/**
 * Render environments table.
 */
import { GlLoadingIcon } from '@gitlab/ui';
import { flow, reverse, sortBy } from 'lodash/fp';
import { s__ } from '~/locale';
import CanaryUpdateModal from './canary_update_modal.vue';
import DeployBoard from './deploy_board.vue';
import EnvironmentItem from './environment_item.vue';

export default {
  components: {
    EnvironmentItem,
    GlLoadingIcon,
    DeployBoard,
    EnvironmentAlert: () => import('ee_component/environments/components/environment_alert.vue'),
    CanaryUpdateModal,
  },
  props: {
    environments: {
      type: Array,
      required: true,
      default: () => [],
    },
    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      canaryWeight: 0,
      environmentToChange: null,
    };
  },
  computed: {
    sortedEnvironments() {
      return this.sortEnvironments(this.environments).map((env) =>
        this.shouldRenderFolderContent(env)
          ? { ...env, children: this.sortEnvironments(env.children) }
          : env,
      );
    },
    tableData() {
      return {
        // percent spacing for cols, should add up to 100
        name: {
          title: s__('Environments|Environment'),
          spacing: 'section-10',
        },
        deploy: {
          title: s__('Environments|Deployment'),
          spacing: 'section-10',
        },
        build: {
          title: s__('Environments|Job'),
          spacing: 'section-15',
        },
        commit: {
          title: s__('Environments|Commit'),
          spacing: 'section-15',
        },
        date: {
          title: s__('Environments|Updated'),
          spacing: 'section-10',
        },
        upcoming: {
          title: s__('Environments|Upcoming'),
          mobileTitle: s__('Environments|Upcoming deployment'),
          spacing: 'section-10',
        },
        autoStop: {
          title: s__('Environments|Auto stop in'),
          spacing: 'section-10',
        },
        actions: {
          spacing: 'section-20',
        },
      };
    },
  },
  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
    shouldRenderDeployBoard(model) {
      return model.hasDeployBoard && model.isDeployBoardVisible;
    },
    shouldRenderFolderContent(env) {
      return env.isFolder && env.isOpen && env.children && env.children.length > 0;
    },
    shouldRenderAlert(env) {
      return env?.has_opened_alert;
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
      return flow(
        sortBy((env) => (env.isFolder ? env.folderName : env.name)),
        reverse,
        sortBy((env) => (env.last_deployment ? env.last_deployment.created_at : '0000')),
        reverse,
        sortBy((env) => (env.isFolder ? -1 : 1)),
      )(environments);
    },
    changeCanaryWeight(model, weight) {
      this.environmentToChange = model;
      this.canaryWeight = weight;
    },
  },
};
</script>
<template>
  <div class="ci-table" role="grid">
    <canary-update-modal :environment="environmentToChange" :weight="canaryWeight" />
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section" :class="tableData.name.spacing" role="columnheader">
        {{ tableData.name.title }}
      </div>
      <div class="table-section" :class="tableData.deploy.spacing" role="columnheader">
        {{ tableData.deploy.title }}
      </div>
      <div class="table-section" :class="tableData.build.spacing" role="columnheader">
        {{ tableData.build.title }}
      </div>
      <div class="table-section" :class="tableData.commit.spacing" role="columnheader">
        {{ tableData.commit.title }}
      </div>
      <div class="table-section" :class="tableData.date.spacing" role="columnheader">
        {{ tableData.date.title }}
      </div>
      <div class="table-section" :class="tableData.upcoming.spacing" role="columnheader">
        {{ tableData.upcoming.title }}
      </div>
      <div class="table-section" :class="tableData.autoStop.spacing" role="columnheader">
        {{ tableData.autoStop.title }}
      </div>
    </div>
    <template v-for="(model, i) in sortedEnvironments" :model="model">
      <environment-item
        :key="`environment-item-${i}`"
        :model="model"
        :can-read-environment="canReadEnvironment"
        :table-data="tableData"
        data-qa-selector="environment_item"
      />

      <div
        v-if="shouldRenderDeployBoard(model)"
        :key="`deploy-board-row-${i}`"
        class="js-deploy-board-row"
      >
        <div class="deploy-board-container">
          <deploy-board
            :deploy-board-data="model.deployBoardData"
            :is-loading="model.isLoadingDeployBoard"
            :is-empty="model.isEmptyDeployBoard"
            :logs-path="model.logs_path"
            @changeCanaryWeight="changeCanaryWeight(model, $event)"
          />
        </div>
      </div>
      <environment-alert
        v-if="shouldRenderAlert(model)"
        :key="`alert-row-${i}`"
        :environment="model"
      />

      <template v-if="shouldRenderFolderContent(model)">
        <div v-if="model.isLoadingFolderContent" :key="`loading-item-${i}`">
          <gl-loading-icon size="md" class="gl-mt-5" />
        </div>

        <template v-else>
          <template v-for="(child, index) in model.children">
            <environment-item
              :key="`environment-row-${i}-${index}`"
              :model="child"
              :can-read-environment="canReadEnvironment"
              :table-data="tableData"
              data-qa-selector="environment_item"
            />

            <div
              v-if="shouldRenderDeployBoard(child)"
              :key="`deploy-board-row-${i}-${index}`"
              class="js-deploy-board-row"
            >
              <div class="deploy-board-container">
                <deploy-board
                  :deploy-board-data="child.deployBoardData"
                  :is-loading="child.isLoadingDeployBoard"
                  :is-empty="child.isEmptyDeployBoard"
                  :logs-path="child.logs_path"
                  @changeCanaryWeight="changeCanaryWeight(child, $event)"
                />
              </div>
            </div>
            <environment-alert
              v-if="shouldRenderAlert(model)"
              :key="`alert-row-${i}-${index}`"
              :environment="child"
            />
          </template>

          <div :key="`sub-div-${i}`">
            <div class="text-center gl-mt-3">
              <a :href="folderUrl(model)" class="btn btn-default">
                {{ s__('Environments|Show all') }}
              </a>
            </div>
          </div>
        </template>
      </template>
    </template>
  </div>
</template>
