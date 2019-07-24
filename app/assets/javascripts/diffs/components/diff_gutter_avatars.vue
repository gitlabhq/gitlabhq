<script>
import { n__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import { truncate } from '~/lib/utils/text_utility';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import { GlTooltipDirective } from '@gitlab/ui';
import { COUNT_OF_AVATARS_IN_GUTTER, LENGTH_OF_AVATAR_TOOLTIP } from '../constants';

export default {
  components: {
    Icon,
    UserAvatarImage,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
    discussionsExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    allDiscussions() {
      return this.discussions.reduce((acc, note) => acc.concat(note.notes), []);
    },
    notesInGutter() {
      return this.allDiscussions.slice(0, COUNT_OF_AVATARS_IN_GUTTER).map(n => ({
        note: n.note,
        author: n.author,
      }));
    },
    moreCount() {
      return this.allDiscussions.length - this.notesInGutter.length;
    },
    moreText() {
      if (this.moreCount === 0) {
        return '';
      }

      return n__('%d more comment', '%d more comments', this.moreCount);
    },
  },
  methods: {
    getTooltipText(noteData) {
      let { note } = noteData;
      if (note.length > LENGTH_OF_AVATAR_TOOLTIP) {
        note = truncate(note, LENGTH_OF_AVATAR_TOOLTIP);
      }

      return `${noteData.author.name}: ${note}`;
    },
  },
};
</script>

<template>
  <div class="diff-comment-avatar-holders">
    <button
      v-if="discussionsExpanded"
      type="button"
      :aria-label="__('Show comments')"
      class="diff-notes-collapse js-diff-comment-avatar js-diff-comment-button"
      @click="$emit('toggleLineDiscussions')"
    >
      <icon :size="12" name="collapse" />
    </button>
    <template v-else>
      <user-avatar-image
        v-for="note in notesInGutter"
        :key="note.id"
        :img-src="note.author.avatar_url"
        :tooltip-text="getTooltipText(note)"
        class="diff-comment-avatar js-diff-comment-avatar"
        @click.native="$emit('toggleLineDiscussions')"
      />
      <span
        v-if="moreText"
        v-gl-tooltip
        :title="moreText"
        class="diff-comments-more-count js-diff-comment-avatar js-diff-comment-plus"
        data-container="body"
        data-placement="top"
        role="button"
        @click="$emit('toggleLineDiscussions')"
        >+{{ moreCount }}</span
      >
    </template>
  </div>
</template>
