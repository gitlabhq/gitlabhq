<script>
/* eslint-disable vue/no-v-html */
import { groupBy } from 'lodash';
import { GlIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { glEmojiTag } from '../../emoji';
import { __, sprintf } from '~/locale';

// Internal constant, specific to this component, used when no `currentUserId` is given
const NO_USER_ID = -1;

export default {
  components: {
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    defaultAwards: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    groupedDefaultAwards() {
      return this.defaultAwards.reduce((obj, key) => Object.assign(obj, { [key]: [] }), {});
    },
    groupedAwards() {
      const { thumbsup, thumbsdown, ...rest } = {
        ...this.groupedDefaultAwards,
        ...groupBy(this.awards, x => x.name),
      };

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
        selected: this.hasReactionByCurrentUser(awardList),
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
      if (!awardsList.length) {
        return '';
      }

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
    <gl-button
      v-for="awardList in groupedAwards"
      :key="awardList.name"
      v-gl-tooltip.viewport
      class="gl-mr-3"
      :class="awardList.classes"
      :title="awardList.title"
      data-testid="award-button"
      @click="handleAward(awardList.name)"
    >
      <template #emoji>
        <span class="award-emoji-block" data-testid="award-html" v-html="awardList.html"></span>
      </template>
      <span class="js-counter">{{ awardList.list.length }}</span>
    </gl-button>
    <div v-if="canAwardEmoji" class="award-menu-holder">
      <gl-button
        v-gl-tooltip.viewport
        :class="addButtonClass"
        class="add-reaction-button js-add-award"
        title="Add reaction"
        :aria-label="__('Add reaction')"
      >
        <span class="reaction-control-icon reaction-control-icon-neutral">
          <gl-icon name="slight-smile" />
        </span>
        <span class="reaction-control-icon reaction-control-icon-positive">
          <gl-icon name="smiley" />
        </span>
        <span class="reaction-control-icon reaction-control-icon-super-positive">
          <gl-icon name="smile" />
        </span>
      </gl-button>
    </div>
  </div>
</template>
