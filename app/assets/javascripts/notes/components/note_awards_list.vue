<script>
import { mapActions, mapGetters } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import Flash from '../../flash';
import { glEmojiTag } from '../../emoji';
import { __, sprintf } from '~/locale';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
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
      type: String,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getUserData']),
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
        if (Object.prototype.hasOwnProperty.call(acc, award.name)) {
          acc[award.name].push(award);
        } else {
          Object.assign(acc, { [award.name]: [award] });
        }

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

      return Object.assign({}, orderedAwards, awards);
    },
    isAuthoredByMe() {
      return this.noteAuthorId === this.getUserData.id;
    },
  },
  methods: {
    ...mapActions(['toggleAwardRequest']),
    getAwardHTML(name) {
      return glEmojiTag(name);
    },
    getAwardClassBindings(awardList) {
      return {
        active: this.hasReactionByCurrentUser(awardList),
        disabled: !this.canInteractWithEmoji(),
      };
    },
    canInteractWithEmoji() {
      return this.getUserData.id;
    },
    hasReactionByCurrentUser(awardList) {
      return awardList.filter(award => award.user.id === this.getUserData.id).length;
    },
    awardTitle(awardsList) {
      const hasReactionByCurrentUser = this.hasReactionByCurrentUser(awardsList);
      const TOOLTIP_NAME_COUNT = hasReactionByCurrentUser ? 9 : 10;
      let awardList = awardsList;

      // Filter myself from list if I am awarded.
      if (hasReactionByCurrentUser) {
        awardList = awardList.filter(award => award.user.id !== this.getUserData.id);
      }

      // Get only 9-10 usernames to show in tooltip text.
      const namesToShow = awardList.slice(0, TOOLTIP_NAME_COUNT).map(award => award.user.name);

      // Get the remaining list to use in `and x more` text.
      const remainingAwardList = awardList.slice(TOOLTIP_NAME_COUNT, awardList.length);

      // Add myself to the beginning of the list so title will start with You.
      if (hasReactionByCurrentUser) {
        namesToShow.unshift(__('You'));
      }

      let title = '';

      // We have 10+ awarded user, join them with comma and add `and x more`.
      if (remainingAwardList.length) {
        title = sprintf(
          __(`%{listToShow}, and %{awardsListLength} more.`),
          {
            listToShow: namesToShow.join(', '),
            awardsListLength: remainingAwardList.length,
          },
          false,
        );
      } else if (namesToShow.length > 1) {
        // Join all names with comma but not the last one, it will be added with and text.
        title = namesToShow.slice(0, namesToShow.length - 1).join(', ');
        // If we have more than 2 users we need an extra comma before and text.
        title += namesToShow.length > 2 ? ',' : '';
        title += sprintf(__(` and %{sliced}`), { sliced: namesToShow.slice(-1) }, false); // Append and text
      } else {
        // We have only 2 users so join them with and.
        title = namesToShow.join(__(' and '));
      }

      return title;
    },
    handleAward(awardName) {
      if (!this.canAwardEmoji) {
        return;
      }

      let parsedName;

      // 100 and 1234 emoji are a number. Callback for v-for click sends it as a string
      switch (awardName) {
        case '100':
          parsedName = 100;
          break;
        case '1234':
          parsedName = 1234;
          break;
        default:
          parsedName = awardName;
          break;
      }

      const data = {
        endpoint: this.toggleAwardPath,
        noteId: this.noteId,
        awardName: parsedName,
      };

      this.toggleAwardRequest(data).catch(() => Flash(__('Something went wrong on our end.')));
    },
  },
};
</script>

<template>
  <div class="note-awards">
    <div class="awards js-awards-block">
      <button
        v-for="(awardList, awardName, index) in groupedAwards"
        :key="index"
        v-tooltip
        :class="getAwardClassBindings(awardList)"
        :title="awardTitle(awardList)"
        data-boundary="viewport"
        class="btn award-control"
        type="button"
        @click="handleAward(awardName)"
      >
        <span v-html="getAwardHTML(awardName)"></span>
        <span class="award-control-text js-counter">{{ awardList.length }}</span>
      </button>
      <div v-if="canAwardEmoji" class="award-menu-holder">
        <button
          v-tooltip
          :class="{ 'js-user-authored': isAuthoredByMe }"
          class="award-control btn js-add-award"
          title="Add reaction"
          :aria-label="__('Add reaction')"
          data-boundary="viewport"
          type="button"
        >
          <span class="award-control-icon award-control-icon-neutral">
            <icon name="slight-smile" />
          </span>
          <span class="award-control-icon award-control-icon-positive">
            <icon name="smiley" />
          </span>
          <span class="award-control-icon award-control-icon-super-positive">
            <icon name="smiley" />
          </span>
          <i
            aria-hidden="true"
            class="fa fa-spinner fa-spin award-control-icon award-control-icon-loading"
          ></i>
        </button>
      </div>
    </div>
  </div>
</template>
