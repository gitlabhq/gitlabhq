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
  import deployBoardSvg from 'empty_states/icons/_deploy_board.svg';
  import instanceComponent from './deploy_board_instance_component.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';

  export default {
    components: {
      instanceComponent,
      loadingIcon,
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
      hasError: {
        type: Boolean,
        required: true,
      },
    },
    data() {
      return {
        deployBoardSvg,
      };
    },
    computed: {
      canRenderDeployBoard() {
        return !this.isLoading && !this.hasError && this.deployBoardData.valid;
      },
      canRenderEmptyState() {
        return !this.isLoading && !this.hasError && !this.deployBoardData.valid;
      },
      canRenderErrorState() {
        return !this.isLoading && this.hasError;
      },
      instanceTitle() {
        let title;

        if (this.deployBoardData.instances.length === 1) {
          title = 'Instance';
        } else {
          title = 'Instances';
        }

        return title;
      },
      projectName() {
        return '<projectname>';
      },
    },
  };
</script>
<template>
  <div class="js-deploy-board deploy-board">

    <div v-if="isLoading">
      <loading-icon />
    </div>

    <div v-if="canRenderDeployBoard">

      <section class="deploy-board-information">
        <span>
          <span class="percentage">{{deployBoardData.completion}}%</span>
          <span class="text">Complete</span>
        </span>
      </section>

      <section class="deploy-board-instances">
        <p class="text">{{instanceTitle}}</p>

        <div class="deploy-board-instances-container">
          <template v-for="instance in deployBoardData.instances">
            <instance-component
              :status="instance.status"
              :tooltip-text="instance.tooltip"
              :stable="instance.stable"
              />
          </template>
        </div>
      </section>

      <section
        class="deploy-board-actions"
        v-if="deployBoardData.rollback_url || deployBoardData.abort_url">
        <a
          class="btn"
          data-method="post"
          rel="nofollow"
          v-if="deployBoardData.rollback_url"
          :href="deployBoardData.rollback_url">
          Rollback
        </a>

        <a
          class="btn btn-red btn-inverted"
          data-method="post"
          rel="nofollow"
          v-if="deployBoardData.abort_url"
          :href="deployBoardData.abort_url">
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
          To see deployment progress for your environments, make sure your deployments are in Kubernetes namespace
          <code>{{projectName}}</code> and labeled with <code>app=$CI_ENVIRONMENT_SLUG</code>.
        </span>
      </section>
    </div>

    <div
      v-if="canRenderErrorState"
      class="deploy-board-error-message">
      We can't fetch the data right now. Please try again later.
    </div>
  </div>
</script>
