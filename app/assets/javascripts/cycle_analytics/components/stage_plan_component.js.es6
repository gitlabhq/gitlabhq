/* eslint-disable no-param-reassign */
/* global Vue */

((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StagePlanComponent = Vue.extend({
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
          <li v-for="commit in items" class="stage-event-item">
            <div class="item-details item-conmmit-component">
              <img class="avatar" :src="commit.author.avatarUrl">
              <h5 class="item-title commit-title">
                <a :href="commit.commitUrl">
                  {{ commit.title }}
                </a>
              </h5>
              <span>
                First
                <span class="commit-icon">${global.cycleAnalytics.svgs.iconCommit}</span>
                <a :href="commit.commitUrl" class="commit-hash-link monospace">{{ commit.shortSha }}</a>
                pushed by
                <a :href="commit.author.webUrl" class="commit-author-link">
                  {{ commit.author.name }}
                </a>
              </span>
            </div>
            <div class="item-time">
              <total-time :time="commit.totalTime"></total-time>
            </div>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
