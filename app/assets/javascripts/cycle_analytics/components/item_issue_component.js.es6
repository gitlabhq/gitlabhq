((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  /*
  `issue` prop should have

  - Issue title
  - Issue URL
  - Issue ID
  - Issue date created
  - Issue author
  - Issue author profile URL
  - Issue author avatar URL
  - Total time
  */

  global.cycleAnalytics.ItemIssueComponent = Vue.extend({
    template: '#item-issue-component',
    props: {
      issue: Object,
    }
  });
})(window.gl || (window.gl = {}));
