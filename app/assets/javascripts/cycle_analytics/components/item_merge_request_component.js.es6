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
    props: {
      mergeRequest: Object,
    },
    template: `
      <div>
        <p>
          <h5>
            <a href="mergeRequest.url">
              {{ mergeRequest.title }}
            </a>
          </h5>
        </p>
      </div>
    `,
  });
}(window.gl || (window.gl = {})));
