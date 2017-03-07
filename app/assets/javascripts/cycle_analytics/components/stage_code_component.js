/* eslint-disable no-param-reassign */
/* global Vue */

((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageCodeComponent = Vue.extend({
    props: {
      items: Array,
      stage: Object,
    },
    template: `
      <div>
        <div class="events-description">
          {{ stage.description }}
        </div>
        <ul class="stage-event-list">
          <li v-for="mergeRequest in items" class="stage-event-item">
            <div class="item-details">
              <img class="avatar" :src="mergeRequest.author.avatarUrl">
              <h5 class="item-title merge-merquest-title">
                <a :href="mergeRequest.url">
                  {{ mergeRequest.title }}
                </a>
              </h5>
              <a :href="mergeRequest.url" class="issue-link">!{{ mergeRequest.iid }}</a>
              &middot;
              <span>
                Opened
                <a :href="mergeRequest.url" class="issue-date">{{ mergeRequest.createdAt }}</a>
              </span>
              <span>
                by
                <a :href="mergeRequest.author.webUrl" class="issue-author-link">{{ mergeRequest.author.name }}</a>
              </span>
            </div>
            <div class="item-time">
              <total-time :time="mergeRequest.totalTime"></total-time>
            </div>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
