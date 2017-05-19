/* eslint-disable no-param-reassign */
import Vue from 'vue';
import iconBranch from '../svg/icon_branch.svg';

const global = window.gl || (window.gl = {});
global.cycleAnalytics = global.cycleAnalytics || {};

global.cycleAnalytics.StageStagingComponent = Vue.extend({
  props: {
    items: Array,
    stage: Object,
  },
  data() {
    return { iconBranch };
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
            <img class="avatar" :src="build.author.avatarUrl">
            <h5 class="item-title">
              <a :href="build.url" class="pipeline-id">#{{ build.id }}</a>
              <i class="fa fa-code-fork"></i>
              <a :href="build.branch.url" class="ref-name">{{ build.branch.name }}</a>
              <span class="icon-branch">${iconBranch}</span>
              <a :href="build.commitUrl" class="commit-sha">{{ build.shortSha }}</a>
            </h5>
            <span>
              <a :href="build.url" class="build-date">{{ build.date }}</a>
              {{ s__('ByAuthor|by') }}
              <a :href="build.author.webUrl" class="issue-author-link">
                {{ build.author.name }}
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
