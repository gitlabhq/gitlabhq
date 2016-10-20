((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageIssueComponent = Vue.extend({
    template: '#stage-issue-component',
    components: {
      'item-issue-component': gl.cycleAnalytics.ItemIssueComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
