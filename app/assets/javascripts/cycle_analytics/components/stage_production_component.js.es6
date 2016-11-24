/* eslint-disable no-param-reassign */
/* global Vue */

((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageProductionComponent = Vue.extend({
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
          <li v-for="issue in items" class="stage-event-item">
            <div class="item-details">
              <img class="avatar" :src="issue.author.avatarUrl">
              <h5 class="item-title issue-title">
                <a class="issue-title" :href="issue.url">
                  {{ issue.title }}
                </a>
              </h5>
              <a :href="issue.url" class="issue-link">#{{ issue.iid }}</a>
              &middot;
              <span>
                Opened
                <a :href="issue.url" class="issue-date">{{ issue.createdAt }}</a>
              </span>
              <span>
              by
              <a :href="issue.author.webUrl" class="issue-author-link">
                {{ issue.author.name }}
              </a>
              </span>
            </div>
            <div class="item-time">
              <total-time :time="issue.totalTime"></total-time>
            </div>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
