((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageStagingComponent = Vue.extend({
    template: '#stage-staging-component',
    components: {
      'item-build-component': gl.cycleAnalytics.ItemBuildComponent,
    },
    props: {
      items: Array,
    },
    template: `
      <div>
        <div class="events-description">
          The time taken in staging
        </div>
        <ul>
          <li v-for="build in items">
            <item-build-component :build="build"></item-build-component>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
