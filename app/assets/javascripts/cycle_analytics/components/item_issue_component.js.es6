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
    },
    template: `
      <div class="item-details">
        <img class="avatar" src="https://secure.gravatar.com/avatar/3731e7dd4f2b4fa8ae184c0a7519dd58?s=64&amp;d=identicon">
        <h5 class="item-title">
          <a href="issue.url">
            {{ issue.title }}
          </a>
        </h5>
        <a href="issue.url" class="issue-link">
          #{{issue.id}}
        </a>
        <span>
          Opened
          <a href="issue.url" class="issue-date">
            {{ issue.datetime }}
          </a>
        </span>
        <span>
        by
        <a href="issue.profile" class="issue-author-link">
          {{ issue.author }}
        </a>
        </span>
      </div>
      <div class="item-time">
        <span class="hours" v-if="issue.totalTime.hours">
          {{ issue.totalTime.hours }}
          <abbr title="Hours">hr</abbr>
        </span>
        <span class="minutes" v-if="issue.totalTime.minutes">
          {{ issue.totalTime.minutes }}
          <abbr title="Minutes">mins</abbr>
        </span>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
