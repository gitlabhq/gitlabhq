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
    props: {
      build: Object,
    },
    template: `
      <div>
        <p>
          <h5>
            <a href="build.url">
              {{ build.title }}
            </a>
          </h5>
        </p>
      </div>
    `,
  });
}(window.gl || (window.gl = {})));
