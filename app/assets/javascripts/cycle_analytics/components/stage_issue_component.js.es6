((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageIssueComponent = Vue.extend({
    components: {
      'item-issue-component': gl.cycleAnalytics.ItemIssueComponent,
    },
    props: {
      items: Array,
    },
    template: `
      <div>
        <div class="events-description">
          Time before an issue get scheluded
        </div>
        <ul class="stage-event-list">
          <li class="stage-event-item" v-for="issue in items">
            <item-issue-component :issue="issue"></item-issue-component>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
