<script>
import { GlIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';

export default {
  components: {
    NoteableDiscussion,
    GlIcon,
    DesignNotePin,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    shouldCollapseDiscussions: {
      type: Boolean,
      required: false,
      default: false,
    },
    renderAvatarBadge: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    ...mapActions('diffs', ['toggleFileDiscussion']),
    isExpanded(discussion) {
      return this.shouldCollapseDiscussions ? discussion.expandedOnDiff : true;
    },
    toggleVisibility(discussion) {
      this.toggleFileDiscussion(discussion);
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(discussion, index) in discussions"
      :key="discussion.id"
      :class="{
        collapsed: !isExpanded(discussion),
      }"
      class="discussion-notes diff-discussions position-relative"
    >
      <ul :data-discussion-id="discussion.id" class="notes">
        <template v-if="shouldCollapseDiscussions">
          <button
            v-if="discussion.expandedOnDiff"
            class="diff-notes-collapse js-diff-notes-toggle"
            type="button"
            :aria-label="__('Show comments')"
            @click="toggleVisibility(discussion)"
          >
            <gl-icon name="collapse" class="collapse-icon" />
          </button>
          <design-note-pin
            v-else
            :label="index + 1"
            :is-resolved="discussion.resolved"
            size="sm"
            class="js-diff-notes-toggle -gl-translate-x-1/2"
            @click="toggleVisibility(discussion)"
          />
        </template>
        <noteable-discussion
          v-show="isExpanded(discussion)"
          :discussion="discussion"
          :render-diff-file="false"
          :discussions-by-diff-order="true"
          :line="line"
          :help-page-path="helpPagePath"
        >
          <template v-if="renderAvatarBadge" #avatar-badge>
            <design-note-pin
              :label="index + 1"
              class="user-avatar"
              :is-resolved="discussion.resolved"
              size="sm"
            />
          </template>
        </noteable-discussion>
      </ul>
    </div>
  </div>
</template>
