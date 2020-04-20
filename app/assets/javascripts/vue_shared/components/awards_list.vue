<script>
import { groupBy } from 'lodash';
import { GlIcon } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import { glEmojiTag } from '../../emoji';
import { __, sprintf } from '~/locale';

// Internal constant, specific to this component, used when no `currentUserId` is given
const NO_USER_ID = -1;

export default {
  components: {
    GlIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    awards: {
      type: Array,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
    currentUserId: {
      type: Number,
      required: false,
      default: NO_USER_ID,
    },
    addButtonClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    groupedAwards() {
      const { thumbsup, thumbsdown, ...rest } = groupBy(this.awards, x => x.name);

      return [
        ...(thumbsup ? [this.createAwardList('thumbsup', thumbsup)] : []),
        ...(thumbsdown ? [this.createAwardList('thumbsdown', thumbsdown)] : []),
        ...Object.entries(rest).map(([name, list]) => this.createAwardList(name, list)),
      ];
    },
    isAuthoredByMe() {
      return this.noteAuthorId === this.currentUserId;
    },
  },
  methods: {
    getAwardClassBindings(awardList) {
      return {
        active: this.hasReactionByCurrentUser(awardList),
        disabled: this.currentUserId === NO_USER_ID,
      };
    },
    hasReactionByCurrentUser(awardList) {
      if (this.currentUserId === NO_USER_ID) {
        return false;
      }

      return awardList.some(award => award.user.id === this.currentUserId);
    },
    createAwardList(name, list) {
      return {
        name,
        list,
        title: this.getAwardListTitle(list),
        classes: this.getAwardClassBindings(list),
        html: glEmojiTag(name),
      };
    },
    getAwardListTitle(awardsList) {
      const hasReactionByCurrentUser = this.hasReactionByCurrentUser(awardsList);
      const TOOLTIP_NAME_COUNT = hasReactionByCurrentUser ? 9 : 10;
      let awardList = awardsList;

      // Filter myself from list if I am awarded.
      if (hasReactionByCurrentUser) {
        awardList = awardList.filter(award => award.user.id !== this.currentUserId);
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

      // 100 and 1234 emoji are a number. Callback for v-for click sends it as a string
      const parsedName = /^[0-9]+$/.test(awardName) ? Number(awardName) : awardName;

      this.$emit('award', parsedName);
    },
  },
};
</script>

<template>
  <div class="awards js-awards-block">
    <button
      v-for="awardList in groupedAwards"
      :key="awardList.name"
      v-tooltip
      :class="awardList.classes"
      :title="awardList.title"
      data-boundary="viewport"
      data-testid="award-button"
      class="btn award-control"
      type="button"
      @click="handleAward(awardList.name)"
    >
      <span data-testid="award-html" v-html="awardList.html"></span>
      <span class="award-control-text js-counter">{{ awardList.list.length }}</span>
    </button>
    <div v-if="canAwardEmoji" class="award-menu-holder">
      <button
        v-tooltip
        :class="addButtonClass"
        class="award-control btn js-add-award"
        title="Add reaction"
        :aria-label="__('Add reaction')"
        data-boundary="viewport"
        type="button"
      >
        <span class="award-control-icon award-control-icon-neutral">
          <gl-icon aria-hidden="true" name="slight-smile" />
        </span>
        <span class="award-control-icon award-control-icon-positive">
          <gl-icon aria-hidden="true" name="smiley" />
        </span>
        <span class="award-control-icon award-control-icon-super-positive">
          <gl-icon aria-hidden="true" name="smiley" />
        </span>
        <i
          aria-hidden="true"
          class="fa fa-spinner fa-spin award-control-icon award-control-icon-loading"
        ></i>
      </button>
    </div>
  </div>
</template>
