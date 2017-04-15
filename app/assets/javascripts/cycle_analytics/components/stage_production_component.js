/* eslint-disable no-param-reassign */
import Vue from 'vue';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';

const global = window.gl || (window.gl = {});
global.cycleAnalytics = global.cycleAnalytics || {};

global.cycleAnalytics.StageProductionComponent = Vue.extend({
  props: {
    items: Array,
    stage: Object,
  },
  components: {
    userAvatarImage,
  },
  template: `
    <div>
      <div class="events-description">
        {{ stage.description }}
        <limit-warning :count="items.length" />
      </div>
      <ul class="stage-event-list">
        <li v-for="issue in items" class="stage-event-item">
          <div class="item-details">
            <!-- FIXME: Pass an alt attribute here for accessibility -->
            <user-avatar-image :img-src="issue.author.avatarUrl"/>
            <h5 class="item-title issue-title">
              <a class="issue-title" :href="issue.url">
                {{ issue.title }}
              </a>
            </h5>
            <a :href="issue.url" class="issue-link">#{{ issue.iid }}</a>
            &middot;
            <span>
              {{ __('OpenedNDaysAgo|Opened') }}
              <a :href="issue.url" class="issue-date">{{ issue.createdAt }}</a>
            </span>
            <span>
            {{ __('ByAuthor|by') }}
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
