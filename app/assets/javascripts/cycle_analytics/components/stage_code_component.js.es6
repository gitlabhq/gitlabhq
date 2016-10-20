((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageCodeComponent = Vue.extend({
    template: '#stage-code-component',
    components: {
      'item-merge-request-component': gl.cycleAnalytics.ItemMergeRequestComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
