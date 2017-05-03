/* eslint-disable no-param-reassign */
/* global Vue */

((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageTestComponent = Vue.extend({
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
          <li v-for="build in items" class="stage-event-item item-build-component">
            <div class="item-details">
              <h5 class="item-title">
                <span class="icon-build-status">${global.cycleAnalytics.svgs.iconBuildStatus}</span>
                <a :href="build.url" class="item-build-name">{{ build.name }}</a>
                &middot;
                <a :href="build.url" class="pipeline-id">#{{ build.id }}</a>
                <i class="fa fa-code-fork"></i>
                <a :href="build.branch.url" class="branch-name monospace">{{ build.branch.name }}</a>
                <span class="icon-branch">${global.cycleAnalytics.svgs.iconBranch}</span>
                <a :href="build.commitUrl" class="short-sha monospace">{{ build.shortSha }}</a>
              </h5>
              <span>
                <a :href="build.url" class="issue-date">
                  {{ build.date }}
                </a>
              </span>
            </div>
            <div class="item-time">
              <total-time :time="build.totalTime"></total-time>
            </div>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
