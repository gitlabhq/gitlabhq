<script>
import { GlButton } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';
import NewLineDiscussionForm from './new_line_discussion_form.vue';
import DiffDiscussions from './diff_discussions.vue';

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
  methods: {
    startAnotherThread() {
      useDiffDiscussions().addNewLineDiscussionForm(this.position);
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
