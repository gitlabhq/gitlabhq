((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StagePlanComponent = Vue.extend({
    components: {
      'item-commit-component': gl.cycleAnalytics.ItemCommitComponent,
    },
    props: {
      items: Array,
    },
    template: `
      <div>
        <div class="events-description">
          Time before an issue starts implementation
        </div>
        <ul class="event-list">
          <li class="event-item" v-for="commit in items">
            <item-commit-component :commit="commit"></item-commit-component>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
