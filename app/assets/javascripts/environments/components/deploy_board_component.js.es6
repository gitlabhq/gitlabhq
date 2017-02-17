/**
 * Renders the deploy boads.
 *
 * A deploy board is composed by several components:
 * - Information area with percentage of completition.
 * - Instances with status.
 * - Button Actions.
 * Mockup: https://gitlab.com/gitlab-org/gitlab-ce/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png
 *
 * The data of each deploy board needs to be fetched when we render the component.
 * Endpoint is /group/project/environments/{id}/status.json
 */

const Vue = require('vue');
const instanceComponent = require('./deploy_board_instance_component');

module.exports = Vue.component('deploy_boards_components', {

  components: {
    instanceComponent,
  },

  created() {
    // Fetch data
    console.log('HERE!');
  },

  template: `
    <div class="js-deploy-board deploy-board">
      <section class="deploy-board-information"></section>

      <section class="deploy-board-instances"></section>

      <section class="deploy-board-actions"></section>
    </div>
  `,
});
