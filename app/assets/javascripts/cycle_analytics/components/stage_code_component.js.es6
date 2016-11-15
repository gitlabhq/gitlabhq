((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageCodeComponent = Vue.extend({
    components: {
      'item-merge-request-component': gl.cycleAnalytics.ItemMergeRequestComponent,
    },
    props: {
      items: Array,
    },
    template: `
      <div>
        <div class="events-description">
          Time spent coding
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
