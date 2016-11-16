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
    props: {
      issue: Object,
    },
    template: `
      <div>
        <div class="item-details">
          <img class="avatar" :src="issue.author.avatar_url">
          <h5 class="item-title">
            <a :href="issue.url">
              {{ issue.title }}
            </a>
          </h5>
          <a :href="issue.url" class="issue-link">
            #{{issue.iid}}
          </a>
          &middot;
          <span>
            Opened
            <a :href="issue.url" class="issue-date">
              {{ issue.createdAt }}
            </a>
          </span>
          <span>
          by
          <a :href="issue.author.web_url" class="issue-author-link">
            {{ issue.author.name }}
          </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="issue.totalTime"></total-time>
        </div>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
