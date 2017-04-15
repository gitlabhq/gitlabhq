/* eslint-disable no-param-reassign */
import Vue from 'vue';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
import iconCommit from '../svg/icon_commit.svg';

const global = window.gl || (window.gl = {});
global.cycleAnalytics = global.cycleAnalytics || {};

global.cycleAnalytics.StagePlanComponent = Vue.extend({
  props: {
    items: Array,
    stage: Object,
  },
  components: {
    userAvatarImage,
  },
  data() {
    return { iconCommit };
  },
  template: `
    <div>
      <div class="events-description">
        {{ stage.description }}
        <limit-warning :count="items.length" />
      </div>
      <ul class="stage-event-list">
        <li v-for="commit in items" class="stage-event-item">
          <div class="item-details item-conmmit-component">
            <!-- FIXME: Pass an alt attribute here for accessibility -->
            <user-avatar-image :img-src="commit.author.avatarUrl"/>
            <h5 class="item-title commit-title">
              <a :href="commit.commitUrl">
                {{ commit.title }}
              </a>
            </h5>
            <span>
              {{ __('FirstPushedBy|First') }}
              <span class="commit-icon">${iconCommit}</span>
              <a :href="commit.commitUrl" class="commit-hash-link commit-sha">{{ commit.shortSha }}</a>
              {{ __('FirstPushedBy|pushed by') }}
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
