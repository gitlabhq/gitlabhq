<script>
/**
 * Renders a deploy board.
 *
 * A deploy board is composed by:
 * - Information area with percentage of completion.
 * - Instances with status.
 * - Button Actions.
 * [Mockup](https://gitlab.com/gitlab-org/gitlab-foss/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png)
 */
import deployBoardSvg from '@gitlab/svgs/dist/illustrations/deploy-boards.svg?raw';
import {
  GlIcon,
  GlLoadingIcon,
  GlLink,
  GlTooltip,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, n__ } from '~/locale';
import InstanceComponent from '~/vue_shared/components/deployment_instance.vue';
import { STATUS_MAP, CANARY_STATUS } from '../constants';
import CanaryIngress from './canary_ingress.vue';

export default {
  components: {
    InstanceComponent,
    CanaryIngress,
    GlIcon,
    GlLoadingIcon,
    GlLink,
    GlSprintf,
    GlTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    deployBoardData: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isEmpty: {
      type: Boolean,
      required: true,
    },
    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    canRenderDeployBoard() {
      return !this.isEmpty && !isEmpty(this.deployBoardData);
    },
    canRenderEmptyState() {
      return this.isEmpty;
    },
    canaryIngress() {
      if (this.graphql) {
        return this.deployBoardData.canaryIngress;
      }

      return this.deployBoardData.canary_ingress;
    },
    canRenderCanaryWeight() {
      return !isEmpty(this.canaryIngress);
    },
    instanceCount() {
      const { instances } = this.deployBoardData;

      return Array.isArray(instances) ? instances.length : 0;
    },
    instanceIsCompletedCount() {
      const completionPercentage = this.deployBoardData.completion / 100;
      const completionCount = Math.floor(completionPercentage * this.instanceCount);

      return Number.isNaN(completionCount) ? 0 : completionCount;
    },
    instanceIsCompletedText() {
      const title = n__('instance completed', 'instances completed', this.instanceIsCompletedCount);

      return `${this.instanceIsCompletedCount} ${title}`;
    },
    instanceTitle() {
      return n__('Instance', 'Instances', this.instanceCount);
    },
    deployBoardSvg() {
      return deployBoardSvg;
    },
    rollbackUrl() {
      if (this.graphql) {
        return this.deployBoardData.rollbackUrl;
      }
      return this.deployBoardData.rollback_url;
    },
    abortUrl() {
      if (this.graphql) {
        return this.deployBoardData.abortUrl;
      }
      return this.deployBoardData.abort_url;
    },
    deployBoardActions() {
      return this.rollbackUrl || this.abortUrl;
    },
    statuses() {
      // Canary is not a pod status but it needs to be in the legend.
      // Hence adding it here.
      return {
        ...STATUS_MAP,
        CANARY_STATUS,
      };
    },
  },
  methods: {
    changeCanaryWeight(weight) {
      this.$emit('changeCanaryWeight', weight);
    },
    podName(instance) {
      if (this.graphql) {
        return instance.podName;
      }

      return instance.pod_name;
    },
  },
  emptyStateText: s__(
    'DeployBoards|To see deployment progress for your environments, make sure you are deploying to %{codeStart}$KUBE_NAMESPACE%{codeEnd} and annotating with %{codeStart}app.gitlab.com/app=$CI_PROJECT_PATH_SLUG%{codeEnd} and %{codeStart}app.gitlab.com/env=$CI_ENVIRONMENT_SLUG%{codeEnd}.',
  ),
};
</script>
<template>
  <div class="js-deploy-board deploy-board">
    <gl-loading-icon v-if="isLoading" size="sm" class="loading-icon" />
    <template v-else>
      <div v-if="canRenderDeployBoard" class="deploy-board-information gl-p-5">
        <div class="deploy-board-information gl-w-full">
          <section class="deploy-board-status">
            <span v-gl-tooltip :title="instanceIsCompletedText">
              <span ref="percentage" class="gl-text-center text-plain gl-font-lg"
                >{{ deployBoardData.completion }}%</span
              >
              <span class="text text-center text-secondary">{{ __('Complete') }}</span>
            </span>
          </section>

          <section class="deploy-board-instances">
            <div class="gl-font-base text-secondary">
              <span class="deploy-board-instances-text"
                >{{ instanceTitle }} ({{ instanceCount }})</span
              >
              <span ref="legend-icon" data-testid="legend-tooltip-target">
                <gl-icon class="gl-text-blue-500 gl-ml-2" name="question-o" />
              </span>
              <gl-tooltip :target="() => $refs['legend-icon']" boundary="#content-body">
                <div class="deploy-board-legend gl-display-flex gl-flex-direction-column">
                  <div
                    v-for="status in statuses"
                    :key="status.text"
                    class="gl-display-flex gl-align-items-center"
                  >
                    <instance-component :status="status.class" :stable="status.stable" />
                    <span class="legend-text gl-ml-3">{{ status.text }}</span>
                  </div>
                </div>
              </gl-tooltip>
            </div>

            <div class="deploy-board-instances-container d-flex flex-wrap flex-row">
              <template v-for="(instance, i) in deployBoardData.instances">
                <instance-component
                  :key="i"
                  :status="instance.status"
                  :tooltip-text="instance.tooltip"
                  :pod-name="podName(instance)"
                  :stable="instance.stable"
                />
              </template>
            </div>
          </section>

          <canary-ingress
            v-if="canRenderCanaryWeight"
            class="deploy-board-canary-ingress"
            :canary-ingress="canaryIngress"
            :graphql="graphql"
            @change="changeCanaryWeight"
          />

          <section v-if="deployBoardActions" class="deploy-board-actions">
            <gl-link
              v-if="rollbackUrl"
              :href="rollbackUrl"
              class="btn"
              data-method="post"
              rel="nofollow"
              >{{ __('Rollback') }}</gl-link
            >
            <gl-link
              v-if="abortUrl"
              :href="abortUrl"
              class="btn btn-danger btn-inverted"
              data-method="post"
              rel="nofollow"
              >{{ __('Abort') }}</gl-link
            >
          </section>
        </div>
      </div>

      <div v-if="canRenderEmptyState" class="deploy-board-empty">
        <section v-safe-html="deployBoardSvg" class="deploy-board-empty-state-svg"></section>

        <section class="deploy-board-empty-state-text">
          <span class="deploy-board-empty-state-title d-flex">{{
            __('Kubernetes deployment not found')
          }}</span>
          <span>
            <gl-sprintf :message="$options.emptyStateText">
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
            </gl-sprintf>
          </span>
        </section>
      </div>
    </template>
  </div>
</template>
