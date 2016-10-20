((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StagePlanComponent = Vue.extend({
    template: '#stage-plan-component',
    components: {
      'item-commit-component': gl.cycleAnalytics.ItemCommitComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
