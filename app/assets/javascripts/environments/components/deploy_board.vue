<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
/**
 * Renders a deploy board.
 *
 * A deploy board is composed by:
 * - Information area with percentage of completion.
 * - Instances with status.
 * - Button Actions.
 * [Mockup](https://gitlab.com/gitlab-org/gitlab-foss/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png)
 */
import deployBoardSvg from '@gitlab/svgs/dist/illustrations/deploy-boards.svg';
import {
  GlIcon,
  GlLoadingIcon,
  GlLink,
  GlTooltip,
  GlTooltipDirective,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { n__ } from '~/locale';
import instanceComponent from '~/vue_shared/components/deployment_instance.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { STATUS_MAP, CANARY_STATUS } from '../constants';
import CanaryIngress from './canary_ingress.vue';

export default {
  components: {
    instanceComponent,
    CanaryIngress,
    GlIcon,
    GlLoadingIcon,
    GlLink,
    GlTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
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
    logsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    canRenderDeployBoard() {
      return !this.isEmpty && !isEmpty(this.deployBoardData);
    },
    canRenderEmptyState() {
      return this.isEmpty;
    },
    canRenderCanaryWeight() {
      return !isEmpty(this.deployBoardData.canary_ingress);
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
    deployBoardActions() {
      return this.deployBoardData.rollback_url || this.deployBoardData.abort_url;
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
  },
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
                <gl-icon class="gl-text-blue-500 gl-ml-2" name="question" />
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
                  :pod-name="instance.pod_name"
                  :logs-path="logsPath"
                  :stable="instance.stable"
                />
              </template>
            </div>
          </section>

          <canary-ingress
            v-if="canRenderCanaryWeight"
            class="deploy-board-canary-ingress"
            :canary-ingress="deployBoardData.canary_ingress"
            @change="changeCanaryWeight"
          />

          <section v-if="deployBoardActions" class="deploy-board-actions">
            <gl-link
              v-if="deployBoardData.rollback_url"
              :href="deployBoardData.rollback_url"
              class="btn"
              data-method="post"
              rel="nofollow"
              >{{ __('Rollback') }}</gl-link
            >
            <gl-link
              v-if="deployBoardData.abort_url"
              :href="deployBoardData.abort_url"
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
            To see deployment progress for your environments, make sure you are deploying to
            <code>$KUBE_NAMESPACE</code> and annotating with
            <code>app.gitlab.com/app=$CI_PROJECT_PATH_SLUG</code>
            and
            <code>app.gitlab.com/env=$CI_ENVIRONMENT_SLUG</code>.
          </span>
        </section>
      </div>
    </template>
  </div>
</template>
