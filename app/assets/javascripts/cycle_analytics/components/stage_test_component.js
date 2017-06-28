/* eslint-disable no-param-reassign */
import Vue from 'vue';
import iconBuildStatus from '../svg/icon_build_status.svg';
import iconBranch from '../svg/icon_branch.svg';

const global = window.gl || (window.gl = {});
global.cycleAnalytics = global.cycleAnalytics || {};

global.cycleAnalytics.StageTestComponent = Vue.extend({
  props: {
    items: Array,
    stage: Object,
  },
  data() {
    return { iconBuildStatus, iconBranch };
  },
  template: `
    <div>
      <div class="events-description">
        {{ stage.description }}
        <limit-warning :count="items.length" />
      </div>
      <ul class="stage-event-list">
        <li v-for="build in items" class="stage-event-item item-build-component">
          <div class="item-details">
            <h5 class="item-title">
              <span class="icon-build-status">${iconBuildStatus}</span>
              <a :href="build.url" class="item-build-name">{{ build.name }}</a>
              &middot;
              <a :href="build.url" class="pipeline-id">#{{ build.id }}</a>
              <i class="fa fa-code-fork"></i>
              <a :href="build.branch.url" class="ref-name">{{ build.branch.name }}</a>
              <span class="icon-branch">${iconBranch}</span>
              <a :href="build.commitUrl" class="commit-sha">{{ build.shortSha }}</a>
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
