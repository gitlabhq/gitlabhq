((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageTestComponent = Vue.extend({
    template: '#stage-test-component',
    components: {
      'item-build-component': gl.cycleAnalytics.ItemBuildComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
