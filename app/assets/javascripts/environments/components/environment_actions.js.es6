const Vue = require('vue');
const playIconSvg = require('../../../../views/shared/icons/_icon_play.svg');

module.exports = Vue.component('actions-component', {
  props: {
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  data() {
    return { playIconSvg };
  },

  template: `
    <div class="btn-group" role="group">
      <button class="dropdown btn btn-default dropdown-new" data-toggle="dropdown">
        <span>
          <span class="js-dropdown-play-icon-container" v-html="playIconSvg"></span>
          <i class="fa fa-caret-down"></i>
        </span>

      <ul class="dropdown-menu dropdown-menu-align-right">
        <li v-for="action in actions">
          <a :href="action.play_path"
            data-method="post"
            rel="nofollow"
            class="js-manual-action-link">
            ${playIconSvg}
            <span>
              {{action.name}}
            </span>
          </a>
        </li>
      </ul>
    </button>
  </div>
  `,
});
