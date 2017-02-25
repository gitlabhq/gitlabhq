/* eslint-disable no-param-reassign */
/* global Vue */
import iconCommit from '../svg/icon_commit.svg';

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
          <span v-if="items.length === 50" class="events-info pull-right">
            <i class="fa fa-warning has-tooltip"
              title="Limited to showing 50 events at most"
              data-placement="top"></i>
            Showing 50 events
          </span>
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
                <span class="commit-icon">${iconCommit}</span>
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
