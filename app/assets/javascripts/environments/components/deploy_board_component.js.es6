/* eslint-disable no-new */
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

const Vue = require('vue');
const instanceComponent = require('./deploy_board_instance_component');
require('~/lib/utils/common_utils');
const Flash = require('~/flash');

module.exports = Vue.component('deploy_boards_components', {

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
  },

  data() {
    return {
      isLoading: false,
      hasError: false,
      backOffRequestCounter: 0,
    };
  },

  created() {
    this.isLoading = true;

    const maxNumberOfRequests = 3;
    const noContentStatus = 204;

    // If the response is 204, we make 3 more requests.
    gl.utils.backOff((next, stop) => {
      this.service.getDeployBoard(this.environmentID)
        .then((resp) => {
          if (resp.status === noContentStatus) {
            this.backOffRequestCounter = this.backOffRequestCounter += 1;

            if (this.backOffRequestCounter < maxNumberOfRequests) {
              next();
            } else {
              stop(resp);
            }
          } else {
            stop(resp);
          }
        })
        .catch(stop);
    })
    .then((resp) => {
      if (resp.status === noContentStatus) {
        this.hasError = true;
        return resp;
      }

      return resp.json();
    })
    .then((response) => {
      this.store.storeDeployBoard(this.environmentID, response);
      return response;
    })
    .then(() => {
      this.isLoading = false;
    })
    .catch(() => {
      this.isLoading = false;
      new Flash('An error occurred while fetching the deploy board.', 'alert');
    });
  },

  computed: {
    canRenderDeployBoard() {
      return !this.isLoading && !this.hasError && Object.keys(this.deployBoardData).length;
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
  },

  template: `
    <div class="js-deploy-board deploy-board">

      <div v-if="isLoading">
        <i class="fa fa-spinner fa-spin"></i>
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
                :tooltipText="instance.tooltip">
              </instance-component>
            </template>
          </div>
        </section>

        <section class="deploy-board-actions">
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

      <div v-if="!isLoading && hasError" class="deploy-board-error-message">
        We can't fetch the data right now. Please try again later.
      </div>
    </div>
  `,
});
