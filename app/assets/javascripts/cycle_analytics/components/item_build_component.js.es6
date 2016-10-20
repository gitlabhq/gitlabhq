((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  /*
  `build` prop should have

  - Build name/title
  - Build ID
  - Build URL
  - Build branch
  - Build branch URL
  - Build short SHA
  - Build commit URL
  - Build date
  - Total time
  */

  global.cycleAnalytics.ItemBuildComponent = Vue.extend({
    template: '#item-build-component',
    props: {
      build: Object,
    }
  });
}(window.gl || (window.gl = {})));
