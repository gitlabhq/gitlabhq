<script>
  /**
   * Renders a deploy board.
   *
   * A deploy board is composed by:
   * - Information area with percentage of completion.
   * - Instances with status.
   * - Button Actions.
   * [Mockup](https://gitlab.com/gitlab-org/gitlab-ce/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png)
   */
  import _ from 'underscore';
  import { n__ } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import deployBoardSvg from 'ee_empty_states/icons/_deploy_board.svg';
  import instanceComponent from './deploy_board_instance_component.vue';

  export default {
    components: {
      instanceComponent,
    },
    directives: {
      tooltip,
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
      logsPath: {
        type: String,
        required: false,
        default: '',
      },
    },
    computed: {
      canRenderDeployBoard() {
        return !this.isLoading && !this.isEmpty && !_.isEmpty(this.deployBoardData);
      },
      canRenderEmptyState() {
        return !this.isLoading && this.isEmpty;
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
      projectName() {
        return '<projectname>';
      },
      deployBoardSvg() {
        return deployBoardSvg;
      },
    },
  };
</script>
<template>
  <div class="js-deploy-board deploy-board">

    <gl-loading-icon v-if="isLoading" />

    <div v-if="canRenderDeployBoard">

      <section class="deploy-board-information">
        <span
          v-tooltip
          :title="instanceIsCompletedText"
        >
          <span class="percentage">{{ deployBoardData.completion }}%</span>
          <span class="text">Complete</span>
        </span>
      </section>

      <section class="deploy-board-instances">
        <p class="text">
          <span>{{ instanceTitle }}</span>
          <span class="total-instances">({{ instanceCount }})</span>
        </p>

        <div class="deploy-board-instances-container">
          <template v-for="(instance, i) in deployBoardData.instances">
            <instance-component
              :status="instance.status"
              :tooltip-text="instance.tooltip"
              :pod-name="instance.pod_name"
              :logs-path="logsPath"
              :stable="instance.stable"
              :key="i"
            />
          </template>
        </div>
      </section>

      <section
        v-if="deployBoardData.rollback_url || deployBoardData.abort_url"
        class="deploy-board-actions"
      >
        <a
          v-if="deployBoardData.rollback_url"
          :href="deployBoardData.rollback_url"
          class="btn"
          data-method="post"
          rel="nofollow">
          Rollback
        </a>

        <a
          v-if="deployBoardData.abort_url"
          :href="deployBoardData.abort_url"
          class="btn btn-red btn-inverted"
          data-method="post"
          rel="nofollow">
          Abort
        </a>
      </section>
    </div>

    <div v-if="canRenderEmptyState">
      <section
        class="deploy-board-empty-state-svg"
        v-html="deployBoardSvg">
      </section>

      <section class="deploy-board-empty-state-text">
        <span class="title">Kubernetes deployment not found</span>
        <span>
          To see deployment progress for your environments,
          make sure your deployments are in Kubernetes namespace
          <code>{{ projectName }}</code> and labeled with <code>app=$CI_ENVIRONMENT_SLUG</code>.
        </span>
      </section>
    </div>
  </div>
</template>
