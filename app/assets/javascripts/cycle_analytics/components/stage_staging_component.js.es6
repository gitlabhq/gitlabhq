((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageStagingComponent = Vue.extend({
    template: '#stage-staging-component',
    components: {
      'item-build-component': gl.cycleAnalytics.ItemBuildComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
