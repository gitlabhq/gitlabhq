((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageProductionComponent = Vue.extend({
    components: {
      'item-issue-component': gl.cycleAnalytics.ItemIssueComponent,
    },
    props: {
      items: Array,
    },
    template: `
      <div>
        <div class="events-description">
          The total time taken from idea to production
        </div>
        <ul>
          <li v-for="issue in items">
            <item-issue-component :issue="issue"></item-issue-component>
          </li>
        </ul>
      </div>
    `
  });

})(window.gl || (window.gl = {}));
