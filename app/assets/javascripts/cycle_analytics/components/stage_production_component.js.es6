((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageProductionComponent = Vue.extend({
    template: '#stage-production-component',
    components: {
      'item-issue-component': gl.cycleAnalytics.ItemIssueComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
