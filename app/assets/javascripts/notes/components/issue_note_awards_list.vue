<script>
import { glEmojiTag } from '~/behaviors/gl_emoji';
import emojiSmiling from '../icons/emoji_slightly_smiling_face.svg';
import emojiSmile from '../icons/emoji_smile.svg';
import emojiSmiley from '../icons/emoji_smiley.svg';

export default {
  props: {
    awards: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      emojiSmiling,
      emojiSmile,
      emojiSmiley,
    };
  },
  computed: {
    // `this.awards` is an array with emojis but they are not grouped by emoji name. See below.
    // [ { name: foo, user: user1 }, { name: bar, user: user1 }, { name: foo, user: user2 } ]
    // This method will group emojis by name their name as an Object. See below.
    // {
    //   foo: [ { name: foo, user: user1 }, { name: foo, user: user2 } ],
    //   bar: [ { name: bar, user: user1 } ]
    // }
    // We need to do this otherwise will will render the same emoji over and over again.
    groupedAwards() {
      const awards = {};

      this.awards.forEach((award) => {
        awards[award.name] = awards[award.name] || [];
        awards[award.name].push(award);
      });

      return awards;
    },
  },
  methods: {
    getAwardHTML(name) {
      return glEmojiTag(name);
    },
    amIAwarded(awardList) {
      const myUserId = window.gon.current_user_id;
      const isAwarded = awardList.filter(award => award.user.id === myUserId);

      return isAwarded.length;
    },
    awardTitle(awardsList) {
      const amIAwarded = this.amIAwarded(awardsList);
      const myUserId = window.gon.current_user_id;
      const TOOLTIP_NAME_COUNT = amIAwarded ? 9 : 10;
      let awardList = awardsList;

      if (amIAwarded) {
        awardList = awardList.filter(award => award.user.id !== myUserId);
      }

      const namesToShow = awardList.slice(0, TOOLTIP_NAME_COUNT).map(award => award.user.name);
      const remainingAwardList = awardList.slice(TOOLTIP_NAME_COUNT, awardList.length);

      if (amIAwarded) {
        namesToShow.unshift('You');
      }

      let title = '';

      if (remainingAwardList.length) {
        title = `${namesToShow.join(', ')}, and ${remainingAwardList.length} more.`;
      } else if (namesToShow.length > 1) {
        title = namesToShow.slice(0, namesToShow.length - 1).join(', ');
        title += namesToShow.length > 2 ? ',' : '';
        title += ` and ${namesToShow.slice(-1)}`;
      } else {
        title = namesToShow.join(' and ');
      }

      return title;
    },
  },
};
</script>

<template>
  <div class="note-awards">
    <div class="awards js-awards-block">
      <button
        v-for="(awardList, awardName) in groupedAwards"
        class="btn award-control has-tooltip"
        :class="{ active: amIAwarded(awardList) }"
        :title="awardTitle(awardList)"
        data-placement="bottom"
        type="button">
        <span v-html="getAwardHTML(awardName)"></span>
        <span class="award-control-text">
          {{awardList.length}}
        </span>
      </button>
      <div class="award-menu-holder">
        <button
          aria-label="Add reaction"
          class="award-control btn has-tooltip"
          data-placement="bottom"
          title="Add reaction"
          type="button">
          <span
            v-html="emojiSmiling"
            class="award-control-icon award-control-icon-neutral"></span>
          <span
            v-html="emojiSmiley"
            class="award-control-icon award-control-icon-positive"></span>
          <span
            v-html="emojiSmile"
            class="award-control-icon award-control-icon-super-positive"></span>
          <i
            aria-hidden="true"
            class="fa fa-spinner fa-spin award-control-icon award-control-icon-loading"></i>
        </button>
      </div>
    </div>
  </div>
</template>
