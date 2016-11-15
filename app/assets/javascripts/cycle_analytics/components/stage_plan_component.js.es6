((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StagePlanComponent = Vue.extend({
    components: {
      'item-commit-component': gl.cycleAnalytics.ItemCommitComponent,
    },
    props: {
      items: Array,
      stage: Object,
    },
    template: `
      <div>
        <div class="events-description">
          {{ stage.shortDescription }}
        </div>
        <ul class="stage-event-list">
          <li class="stage-event-item" v-for="commit in items">
            <item-commit-component :commit="commit"></item-commit-component>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
