((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  /*
  `commit` prop should have

  - Commit title
  - Commit URL
  - Commit Short SHA
  - Commit author
  - Commit author profile URL
  - Commit author avatar URL
  - Total time
  */

  global.cycleAnalytics.ItemCommitComponent = Vue.extend({
    template: '#item-commit-component',
    props: {
      commit: Object,
    }
  });
}(window.gl || (window.gl = {})));
