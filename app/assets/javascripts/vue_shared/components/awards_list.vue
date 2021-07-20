<script>
/* eslint-disable vue/no-v-html */
import { GlIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { groupBy } from 'lodash';
import EmojiPicker from '~/emoji/components/picker.vue';
import { __, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { glEmojiTag } from '../../emoji';

// Internal constant, specific to this component, used when no `currentUserId` is given
const NO_USER_ID = -1;

export default {
  components: {
    GlButton,
    GlIcon,
    EmojiPicker,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
    selectedClass: {
      type: String,
      required: false,
      default: 'selected',
    },
  },
  data() {
    return {
      isMenuOpen: false,
    };
  },
  computed: {
    groupedDefaultAwards() {
      return this.defaultAwards.reduce((obj, key) => Object.assign(obj, { [key]: [] }), {});
    },
    groupedAwards() {
      const { thumbsup, thumbsdown, ...rest } = {
        ...this.groupedDefaultAwards,
        ...groupBy(this.awards, (x) => x.name),
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
        [this.selectedClass]: this.hasReactionByCurrentUser(awardList),
        disabled: this.currentUserId === NO_USER_ID,
      };
    },
    hasReactionByCurrentUser(awardList) {
      if (this.currentUserId === NO_USER_ID) {
        return false;
      }

      return awardList.some((award) => award.user.id === this.currentUserId);
    },
    createAwardList(name, list) {
      return {
        name,
        list,
        title: this.getAwardListTitle(list, name),
        classes: this.getAwardClassBindings(list),
        html: glEmojiTag(name),
      };
    },
    getAwardListTitle(awardsList, name) {
      if (!awardsList.length) {
        return '';
      }

      const hasReactionByCurrentUser = this.hasReactionByCurrentUser(awardsList);
      const TOOLTIP_NAME_COUNT = hasReactionByCurrentUser ? 9 : 10;
      let awardList = awardsList;

      // Filter myself from list if I am awarded.
      if (hasReactionByCurrentUser) {
        awardList = awardList.filter((award) => award.user.id !== this.currentUserId);
      }

      // Get only 9-10 usernames to show in tooltip text.
      const namesToShow = awardList.slice(0, TOOLTIP_NAME_COUNT).map((award) => award.user.name);

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
          __(`%{listToShow}, and %{awardsListLength} more`),
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

      return title + sprintf(__(' reacted with :%{name}:'), { name });
    },
    handleAward(awardName) {
      if (!this.canAwardEmoji) {
        return;
      }

      // 100 and 1234 emoji are a number. Callback for v-for click sends it as a string
      const parsedName = /^[0-9]+$/.test(awardName) ? Number(awardName) : awardName;

      this.$emit('award', parsedName);

      if (document.activeElement) document.activeElement.blur();
    },
    setIsMenuOpen(menuOpen) {
      this.isMenuOpen = menuOpen;
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
      class="gl-mr-3 gl-my-2"
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
    <div v-if="canAwardEmoji" class="award-menu-holder gl-my-2">
      <emoji-picker
        v-if="glFeatures.improvedEmojiPicker"
        :toggle-class="['add-reaction-button btn-icon gl-relative!', { 'is-active': isMenuOpen }]"
        @click="handleAward"
        @shown="setIsMenuOpen(true)"
        @hidden="setIsMenuOpen(false)"
      >
        <template #button-content>
          <span class="reaction-control-icon reaction-control-icon-neutral">
            <gl-icon name="slight-smile" />
          </span>
          <span class="reaction-control-icon reaction-control-icon-positive">
            <gl-icon name="smiley" />
          </span>
          <span class="reaction-control-icon reaction-control-icon-super-positive">
            <gl-icon name="smile" />
          </span>
        </template>
      </emoji-picker>
      <gl-button
        v-else
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
