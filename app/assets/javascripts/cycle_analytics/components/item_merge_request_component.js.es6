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
        <div class="item-details">
          <img class="avatar" :src="mergeRequest.author.avatarUrl">
          <h5 class="item-title">
            <a :href="mergeRequest.url">
              {{ mergeRequest.title }}
            </a>
          </h5>
          <a :href="mergeRequest.url" class="issue-link">
            !{{ mergeRequest.iid }}
          </a>
          &middot;
          <span>
            Opened
            <a :href="mergeRequest.url" class="issue-date">
              {{ mergeRequest.createdAt }}
            </a>
          </span>
          <span>
          by
          <a :href="mergeRequest.author.webUrl" class="issue-author-link">
            {{ mergeRequest.author.name }}
          </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="mergeRequest.totalTime"></total-time>
        </div>
      </div>
    `,
  });
}(window.gl || (window.gl = {})));
