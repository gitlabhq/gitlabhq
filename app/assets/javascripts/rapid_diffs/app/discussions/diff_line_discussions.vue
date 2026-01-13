<script>
import { GlButton } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';
import NewLineDiscussionForm from './new_line_discussion_form.vue';
import DiffDiscussions from './diff_discussions.vue';

// we only need to scroll to the note once, this value would be shared across all instances of the component
// we don't need it to be reactive so we can just use the module closure to store it
let scrolledToNote = false;

export default {
  name: 'DiffLineDiscussions',
  components: {
    GlButton,
    NoteSignedOutWidget,
    NewLineDiscussionForm,
    DiffDiscussions,
  },
  inject: {
    userPermissions: {
      type: Object,
    },
  },
  props: {
    position: {
      type: Object,
      required: true,
    },
  },
  emits: ['empty'],
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    discussions() {
      return useDiffDiscussions()
        .findDiscussionsForPosition(this.position)
        .filter((discussion) => !discussion.hidden);
    },
    hasForm() {
      return this.discussions.some((discussion) => discussion.isForm);
    },
  },
  watch: {
    discussions(value) {
      if (value.length === 0) this.$emit('empty');
    },
  },
  mounted() {
    this.scrollToNoteFragment();
  },
  methods: {
    startAnotherThread() {
      useDiffDiscussions().addNewLineDiscussionForm(this.position);
    },
    scrollToNoteFragment() {
      if (!window.location.hash.startsWith('#note_') || scrolledToNote) return;
      const target = document.querySelector(`a[href="${window.location.hash}"]`);
      if (!target) return;
      // :target pseudo class applies to the note only if we click the link since the note is rendered client-side
      target.click();
      scrolledToNote = true;
    },
  },
};
</script>

<template>
  <div v-if="discussions.length">
    <div
      v-for="(discussion, index) in discussions"
      :key="index"
      :class="{ 'gl-border-t': index > 0 }"
    >
      <new-line-discussion-form v-if="discussion.isForm" :discussion="discussion" />
      <!-- eslint-disable-next-line @gitlab/vue-no-new-non-primitive-in-template -->
      <diff-discussions v-else :discussions="[discussion]" />
    </div>
    <div v-if="!hasForm" class="gl-border-t gl-flex gl-border-t-subtle gl-px-5 gl-py-4">
      <note-signed-out-widget v-if="!isLoggedIn" />
      <gl-button v-else-if="userPermissions.can_create_note" @click="startAnotherThread">
        {{ __('Start another thread') }}
      </gl-button>
    </div>
  </div>
</template>
