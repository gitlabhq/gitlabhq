<script>
import { GlButton } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';
import NewLineDiscussionForm from './new_line_discussion_form.vue';
import DiffDiscussions from './diff_discussions.vue';
import DraftNote from './draft_note.vue';

export default {
  name: 'DiffLineDiscussions',
  components: {
    GlButton,
    NoteSignedOutWidget,
    NewLineDiscussionForm,
    DiffDiscussions,
    DraftNote,
  },
  inject: {
    userPermissions: { type: Object },
    filePaths: { default: null },
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['start-thread', 'highlight', 'clear-highlight'],
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    regularDiscussions() {
      return this.discussions.filter((discussion) => !discussion.isDraft);
    },
    draftDiscussions() {
      return this.discussions.filter((discussion) => discussion.isDraft);
    },
    hasForm() {
      return this.discussions.some((discussion) => discussion.isForm);
    },
  },
  methods: {
    lineRange(discussion) {
      const { position } = discussion;
      if (position?.line_range) return position.line_range;
      return {
        start: { old_line: position?.old_line, new_line: position?.new_line },
        end: { old_line: position?.old_line, new_line: position?.new_line },
      };
    },
    onMouseenter(discussion) {
      this.$emit('highlight', this.lineRange(discussion));
    },
    onMouseleave() {
      this.$emit('clear-highlight');
    },
  },
};
</script>

<template>
  <div class="rd-diff-line-discussions-list">
    <div
      v-for="(discussion, index) in regularDiscussions"
      :key="index"
      :class="{ 'gl-border-t': index > 0 }"
      @mouseenter="onMouseenter(discussion)"
      @mouseleave="onMouseleave"
    >
      <new-line-discussion-form v-if="discussion.isForm" :discussion="discussion" />
      <!-- eslint-disable-next-line @gitlab/vue-no-new-non-primitive-in-template -->
      <diff-discussions v-else :discussions="[discussion]" />
    </div>
    <div
      v-if="!hasForm && !collapsed"
      class="gl-border-t gl-flex gl-border-t-subtle gl-px-4 gl-py-4"
    >
      <note-signed-out-widget v-if="!isLoggedIn" />
      <gl-button v-else-if="userPermissions.can_create_note" @click="$emit('start-thread')">
        {{ __('Start another thread') }}
      </gl-button>
    </div>
    <div
      v-for="(discussion, index) in draftDiscussions"
      :key="discussion.id"
      @mouseenter="onMouseenter(discussion)"
      @mouseleave="onMouseleave"
    >
      <draft-note
        :class="{
          'gl-rounded-[var(--content-border-radius)]': index === draftDiscussions.length - 1,
        }"
        :draft="discussion.draft"
      />
    </div>
  </div>
</template>
