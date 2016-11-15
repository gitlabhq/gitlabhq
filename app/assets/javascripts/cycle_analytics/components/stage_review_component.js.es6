((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageReviewComponent = Vue.extend({
    components: {
      'item-merge-request-component': gl.cycleAnalytics.ItemMergeRequestComponent,
    },
    props: {
      items: Array,
    },
    template: `
      <div>
        <div class="events-description">
          The time taken to review the code
        </div>
        <ul class="stage-event-list">
          <li class="stage-event-item" v-for="mergeRequest in items">
            <item-merge-request-component :merge-request="mergeRequest"></item-merge-request-component>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
