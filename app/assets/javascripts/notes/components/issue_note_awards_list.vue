<script>
  /* global Flash */

  import { mapActions } from 'vuex';
  import emojiSmiling from 'icons/_emoji_slightly_smiling_face.svg';
  import emojiSmile from 'icons/_emoji_smile.svg';
  import emojiSmiley from 'icons/_emoji_smiley.svg';
  import * as Emoji from '../../emoji';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    props: {
      awards: {
        type: Array,
        required: true,
      },
      toggleAwardPath: {
        type: String,
        required: true,
      },
      noteAuthorId: {
        type: Number,
        required: true,
      },
      noteId: {
        type: Number,
        required: true,
      },
    },
    directives: {
      tooltip,
    },
    data() {
      const userId = window.gon.current_user_id;

      return {
        emojiSmiling,
        emojiSmile,
        emojiSmiley,
        canAward: !!userId,
        myUserId: userId,
      };
    },
    computed: {
      // `this.awards` is an array with emojis but they are not grouped by emoji name. See below.
      // [ { name: foo, user: user1 }, { name: bar, user: user1 }, { name: foo, user: user2 } ]
      // This method will group emojis by their name as an Object. See below.
      // {
      //   foo: [ { name: foo, user: user1 }, { name: foo, user: user2 } ],
      //   bar: [ { name: bar, user: user1 } ]
      // }
      // We need to do this otherwise we will render the same emoji over and over again.
      groupedAwards() {
        const awards = this.awards.reduce((acc, award) => {
          Object.assign(acc, {[award.name]: [award]});
          return acc;
        }, {});

        const orderedAwards = {};
        const { thumbsdown, thumbsup } = awards;
        // Always show thumbsup and thumbsdown first
        if (thumbsup) {
          orderedAwards.thumbsup = thumbsup;
          delete awards.thumbsup;
        }
        if (thumbsdown) {
          orderedAwards.thumbsdown = thumbsdown;
          delete awards.thumbsdown;
        }
        return  Object.assign({}, orderedAwards, awards);
      },
      isAuthoredByMe() {
        return this.noteAuthorId === window.gon.current_user_id;
      },
    },
    methods: {
      ...mapActions([
        'toggleAward',
      ]),
      getAwardHTML(name) {
        return Emoji.glEmojiTag(name);
      },
      getAwardClassBindings(awardList, awardName) {
        return {
          active: this.hasReactionByCurrentUser(awardList),
          disabled: !this.canInteractWithEmoji(awardList, awardName),
        };
      },
      canInteractWithEmoji(awardList, awardName) {
        let isAllowed = true;
        const restrictedEmojis = ['thumbsup', 'thumbsdown'];
        const { myUserId, noteAuthorId } = this;

        // Users can not add :+1: and :-1: to their own notes
        if (myUserId === noteAuthorId && restrictedEmojis.indexOf(awardName) > -1) {
          isAllowed = false;
        }

        return this.canAward && isAllowed;
      },
      hasReactionByCurrentUser(awardList) {
        return awardList.filter(award => award.user.id === this.myUserId).length;
      },
      awardTitle(awardsList) {
        const hasReactionByCurrentUser = this.hasReactionByCurrentUser(awardsList);
        const TOOLTIP_NAME_COUNT = hasReactionByCurrentUser ? 9 : 10;
        let awardList = awardsList;

        // Filter myself from list if I am awarded.
        if (hasReactionByCurrentUser) {
          awardList = awardList.filter(award => award.user.id !== this.myUserId);
        }

        // Get only 9-10 usernames to show in tooltip text.
        const namesToShow = awardList.slice(0, TOOLTIP_NAME_COUNT).map(award => award.user.name);

        // Get the remaining list to use in `and x more` text.
        const remainingAwardList = awardList.slice(TOOLTIP_NAME_COUNT, awardList.length);

        // Add myself to the begining of the list so title will start with You.
        if (hasReactionByCurrentUser) {
          namesToShow.unshift('You');
        }

        let title = '';

        // We have 10+ awarded user, join them with comma and add `and x more`.
        if (remainingAwardList.length) {
          title = `${namesToShow.join(', ')}, and ${remainingAwardList.length} more.`;
        } else if (namesToShow.length > 1) {
          // Join all names with comma but not the last one, it will be added with and text.
          title = namesToShow.slice(0, namesToShow.length - 1).join(', ');
          // If we have more than 2 users we need an extra comma before and text.
          title += namesToShow.length > 2 ? ',' : '';
          title += ` and ${namesToShow.slice(-1)}`; // Append and text
        } else { // We have only 2 users so join them with and.
          title = namesToShow.join(' and ');
        }

        return title;
      },
      handleAward(awardName) {
        const data = {
          endpoint: this.toggleAwardPath,
          noteId: this.noteId,
        // 100 emoji is a number. Callback for v-for click sends it as a string
          awardName: awardName === "100" ? 100: awardName,
        };

        this.toggleAward(data)
          .catch(() => Flash('Something went wrong on our end.'));
      },
    },
  };
</script>

<template>
  <div class="note-awards">
    <div class="awards js-awards-block">
      <button
        v-tooltip
        v-for="(awardList, awardName, index) in groupedAwards"
        :key="index"
        :class="getAwardClassBindings(awardList, awardName)"
        :title="awardTitle(awardList)"
        @click="handleAward(awardName)"
        class="btn award-control"
        data-placement="bottom"
        type="button">
        <span v-html="getAwardHTML(awardName)"></span>
        <span class="award-control-text js-counter">
          {{awardList.length}}
        </span>
      </button>
      <div
        v-if="canAward"
        class="award-menu-holder">
        <button
          v-tooltip
          :class="{ 'js-user-authored': isAuthoredByMe }"
          class="award-control btn js-add-award"
          title="Add reaction"
          aria-label="Add reaction"
          data-placement="bottom"
          type="button">
          <span
            v-html="emojiSmiling"
            class="award-control-icon award-control-icon-neutral">
          </span>
          <span
            v-html="emojiSmiley"
            class="award-control-icon award-control-icon-positive">
          </span>
          <span
            v-html="emojiSmile"
            class="award-control-icon award-control-icon-super-positive">
          </span>
          <i
            aria-hidden="true"
            class="fa fa-spinner fa-spin award-control-icon award-control-icon-loading"></i>
        </button>
      </div>
    </div>
  </div>
</template>
