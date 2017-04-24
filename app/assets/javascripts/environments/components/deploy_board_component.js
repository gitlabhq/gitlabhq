/* global Flash */
/**
 * Renders a deploy board.
 *
 * A deploy board is composed by:
 * - Information area with percentage of completion.
 * - Instances with status.
 * - Button Actions.
 * [Mockup](https://gitlab.com/gitlab-org/gitlab-ce/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png)
 *
 * The data of each deploy board needs to be fetched when we render the component.
 *
 * The endpoint response can sometimes be 204, in those cases we need to retry the request.
 * This should be done using backoff pooling and we should make no more than 3 request
 * for each deploy board.
 * After the third request we need to show a message saying we can't fetch the data.
 * Please refer to this [comment](https://gitlab.com/gitlab-org/gitlab-ee/issues/1589#note_23630610)
 * for more information
 */
import Visibility from 'visibilityjs';
import deployBoardSvg from 'empty_states/icons/_deploy_board.svg';
import instanceComponent from './deploy_board_instance_component';
import Poll from '../../lib/utils/poll';
import '../../flash';

export default {

  components: {
    instanceComponent,
  },

  props: {
    store: {
      type: Object,
      required: true,
    },

    service: {
      type: Object,
      required: true,
    },

    deployBoardData: {
      type: Object,
      required: true,
    },

    environmentID: {
      type: Number,
      required: true,
    },

    endpoint: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      isLoading: false,
      hasError: false,
      deployBoardSvg,
    };
  },

  created() {
    const poll = new Poll({
      resource: this.service,
      method: 'getDeployBoard',
      data: this.endpoint,
      successCallback: this.successCallback,
      errorCallback: this.errorCallback,
    });

    if (!Visibility.hidden()) {
      this.isLoading = true;
      poll.makeRequest();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        poll.restart();
      } else {
        poll.stop();
      }
    });
  },

  methods: {
    successCallback(response) {
      const data = response.json();

      this.store.storeDeployBoard(this.environmentID, data);
      this.isLoading = false;
    },

    errorCallback() {
      this.isLoading = false;
      // eslint-disable-next-line no-new
      new Flash('An error occurred while fetching the deploy board.');
    },
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

  template: `
    <div class="js-deploy-board deploy-board">

      <div v-if="isLoading">
        <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
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
                :stable="instance.stable" />
            </template>
          </div>
        </section>

        <section class="deploy-board-actions" v-if="deployBoardData.rollback_url || deployBoardData.abort_url">
          <a class="btn"
            data-method="post"
            rel="nofollow"
            v-if="deployBoardData.rollback_url"
            :href="deployBoardData.rollback_url">
            Rollback
          </a>

          <a class="btn btn-red btn-inverted"
            data-method="post"
            rel="nofollow"
            v-if="deployBoardData.abort_url"
            :href="deployBoardData.abort_url">
            Abort
          </a>
        </section>
      </div>

      <div v-if="canRenderEmptyState">
        <section class="deploy-board-empty-state-svg">
          ${deployBoardSvg}
        </section>

        <section class="deploy-board-empty-state-text">
          <span class="title">Kubernetes deployment not found</span>
          <span>
            To see deployment progress for your environments, make sure your deployments are in Kubernetes namespace
            <code>{{projectName}}</code> and labeled with <code>app=$CI_ENVIRONMENT_SLUG</code>.
          </span>
        </section>
      </div>

      <div v-if="canRenderErrorState" class="deploy-board-error-message">
        We can't fetch the data right now. Please try again later.
      </div>
    </div>
  `,
};
