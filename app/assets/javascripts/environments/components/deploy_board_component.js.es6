/**
 * Renders a deploy board.
 *
 * A deploy board is composed by:
 * - Information area with percentage of completition.
 * - Instances with status.
 * - Button Actions.
 * [Mockup](https://gitlab.com/gitlab-org/gitlab-ce/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png)
 *
 * The data of each deploy board needs to be fetched when we render the component.
 * Endpoint is /group/project/environments/{id}/status.json
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

module.exports = Vue.component('deploy_boards_components', {

  components: {
    instanceComponent,
  },

  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      isLoading: false,
      hasContent: false,
      hasError: false,
    };
  },

  created() {
    // Fetch data
    console.log('HERE!');
  },

  template: `
    <div class="js-deploy-board deploy-board">

      <div v-if="isLoading">
        <i class="fa fa-spinner fa-spin"></i>
      </div>

      <div v-if="!isLoading && hasContent">
        <section class="deploy-board-information">

        </section>

        <section class="deploy-board-instances">
          <p>Instances</p>

          <div class="deploy-board-instances-container">

          </div>
        </section>

        <section class="deploy-board-actions"></section>
      </div>

      <div v-if="!isLoading && hasError">
        We can't fetch the data right now. Please try again later.
      </div>
    </div>
  `,
});
