((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  /*
  `mergeRequest` prop should have

  - MR title
  - MR URL
  - MR ID
  - MR date opened
  - MR author
  - MR author profile URL
  - MR author avatar URL
  - Total time
  */

  global.cycleAnalytics.ItemMergeRequestComponent = Vue.extend({
    template: '#item-merge-request-component',
    props: {
      mergeRequest: Object,
    }
  });
}(window.gl || (window.gl = {})));
