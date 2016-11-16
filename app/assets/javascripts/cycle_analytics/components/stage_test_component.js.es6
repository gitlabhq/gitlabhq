((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageTestComponent = Vue.extend({
    components: {
      'item-build-component': gl.cycleAnalytics.ItemBuildComponent,
    },
    props: {
      items: Array,
      stage: Object,
    },
    template: `
      <div>
        <div class="events-description">
          {{ stage.description }}
        </div>
        <ul class="stage-event-list">
          <li class="stage-event-item" v-for="build in items">
            <item-build-component :build="build"></item-build-component>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
