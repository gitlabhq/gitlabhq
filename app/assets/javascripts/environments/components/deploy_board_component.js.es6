/* eslint-disable no-new, import/first */
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

const instanceComponent = require('./deploy_board_instance_component.js.es6');
const statusCodes = require('~/lib/utils/http_status');
const Flash = require('~/flash');
require('~/lib/utils/common_utils.js.es6');

module.exports = {

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
      backOffRequestCounter: 0,
    };
  },

  created() {
    this.isLoading = true;

    const maxNumberOfRequests = 3;

    // If the response is 204, we make 3 more requests.
    gl.utils.backOff((next, stop) => {
      this.service.getDeployBoard(this.endpoint)
        .then((resp) => {
          if (resp.status === statusCodes.NO_CONTENT) {
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
      if (resp.status === statusCodes.NO_CONTENT) {
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
                :tooltipText="instance.tooltip"/>
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
          <svg width="55" height="44" viewBox="0 0 55 44" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd"><g transform="translate(1.488 .803)"><rect stroke="#E5E5E5" stroke-width="1.6" fill="#FFF" width="42" height="42" rx="4"/><rect stroke="#E7E7E7" stroke-width="1.6" fill="#FFF" x="6" y="12" width="7.171" height="24" rx="2"/><rect stroke="#B5A7DD" stroke-width="1.6" fill="#FFF" x="6" y="5" width="32.17" height="3.5" rx="1.75"/><rect stroke="#FDE5D8" stroke-width="1.6" fill="#FFF" x="17" y="12" width="21.17" height="24" rx="2"/><rect fill="#E52C5A" x="19.74" y="14.197" width="7.171" height="2.408" rx="1.204"/><rect fill="#E5E5E5" x="28.35" y="18.272" width="7.171" height="2.408" rx="1.204"/><rect fill="#E5E5E5" x="19.74" y="26.697" width="15.943" height="2.408" rx="1.204"/><rect fill="#E5E5E5" x="19.74" y="30.697" width="15.943" height="2.408" rx="1.204"/><rect fill="#E52C5A" x="21.911" y="21.272" width="4.78" height="2.408" rx="1.204"/><rect fill="#FC8A51" x="28.472" y="22.429" width="7.171" height="2.408" rx="1.204"/><rect fill="#FDE5D8" x="26.691" y="8.429" width="2.39" height="2.408" rx="1.195"/><rect fill="#FF8340" x="8.512" y="14.85" width="2.39" height="2.408" rx="1.195"/><rect fill="#E52C5A" x="8.512" y="19.197" width="2.39" height="2.408" rx="1.195"/><rect fill="#FF8340" x="8.512" y="31.197" width="2.39" height="2.408" rx="1.195"/><rect fill="#E7E7E7" x="8.512" y="27.197" width="2.39" height="2.408" rx="1.195"/><rect fill="#B5A7DD" x="8.512" y="23.197" width="2.39" height="2.408" rx="1.195"/></g><g transform="rotate(-45 33.371 -12.99)"><ellipse stroke="#6B4FBB" stroke-width="3.2" fill-opacity=".1" fill="#FFF" cx="11.951" cy="12.041" rx="11.951" ry="12.041"/><path d="M5.536 22.29c5.716 3.3 13.046 1.307 16.37-4.452 3.326-5.759 1.387-13.103-4.329-16.403" stroke="#6B4FBB" stroke-width="3.2" fill-opacity=".3" fill="#FFF"/><rect fill="#6B4FBB" x="9.561" y="23.279" width="4.78" height="13.646" rx="2.39"/></g></g></svg>
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
