((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageReviewComponent = Vue.extend({
    template: '#stage-review-component',
    components: {
      'item-merge-request-component': gl.cycleAnalytics.ItemMergeRequestComponent,
    },
    props: {
      items: Array,
    }
  });

})(window.gl || (window.gl = {}));
