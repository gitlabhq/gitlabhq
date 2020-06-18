<script>
import { mapActions, mapGetters } from 'vuex';
import { IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { sprintf, __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import resolvedStatusMixin from '../mixins/resolved_status';
import { GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
} from '~/notes/components/multiline_comment_utils';

export default {
  components: {
    Icon,
    GlSprintf,
  },
  mixins: [resolvedStatusMixin, glFeatureFlagsMixin()],
  props: {
    draft: {
      type: Object,
      required: true,
    },
    isLast: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters(['getDiscussion']),
    iconName() {
      return this.isDiffDiscussion || this.draft.line_code ? 'doc-text' : 'comment';
    },
    discussion() {
      return this.getDiscussion(this.draft.discussion_id);
    },
    isDiffDiscussion() {
      return this.discussion && this.discussion.diff_discussion;
    },
    titleText() {
      const file = this.discussion ? this.discussion.diff_file : this.draft;

      if (file) {
        return file.file_path;
      }

      return sprintf(__("%{authorsName}'s thread"), {
        authorsName: this.discussion.notes.find(note => !note.system).author.name,
      });
    },
    linePosition() {
      if (this.draft.position && this.draft.position.position_type === IMAGE_DIFF_POSITION_TYPE) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        return `${this.draft.position.x}x ${this.draft.position.y}y`;
      }

      const position = this.discussion ? this.discussion.position : this.draft.position;

      return position?.new_line || position?.old_line;
    },
    content() {
      const el = document.createElement('div');
      el.innerHTML = this.draft.note_html;

      return el.textContent;
    },
    showLinePosition() {
      return this.draft.file_hash || this.isDiffDiscussion;
    },
    startLineNumber() {
      return getStartLineNumber(this.draft.position?.line_range);
    },
    endLineNumber() {
      return getEndLineNumber(this.draft.position?.line_range);
    },
  },
  methods: {
    ...mapActions('batchComments', ['scrollToDraft']),
    getLineClasses(lineNumber) {
      return getLineClasses(lineNumber);
    },
  },
  showStaysResolved: false,
};
</script>

<template>
  <button
    type="button"
    class="review-preview-item menu-item"
    :class="[
      componentClasses,
      {
        'is-last': isLast,
      },
    ]"
    @click="scrollToDraft(draft)"
  >
    <span class="review-preview-item-header">
      <icon class="flex-shrink-0" :name="iconName" />
      <span
        class="bold text-nowrap"
        :class="{ 'gl-align-items-center': glFeatures.multilineComments }"
      >
        <span class="review-preview-item-header-text block-truncated">
          {{ titleText }}
        </span>
        <template v-if="showLinePosition">
          <template v-if="!glFeatures.multilineComments"
            >:{{ linePosition }}</template
          >
          <template v-else-if="startLineNumber === endLineNumber">
            :<span :class="getLineClasses(startLineNumber)">{{ startLineNumber }}</span>
          </template>
          <gl-sprintf v-else :message="__(':%{startLine} to %{endLine}')">
            <template #startLine>
              <span class="gl-mr-2" :class="getLineClasses(startLineNumber)">{{
                startLineNumber
              }}</span>
            </template>
            <template #endLine>
              <span class="gl-ml-2" :class="getLineClasses(endLineNumber)">{{
                endLineNumber
              }}</span>
            </template>
          </gl-sprintf>
        </template>
      </span>
    </span>
    <span class="review-preview-item-content">
      <p>{{ content }}</p>
    </span>
    <span
      v-if="draft.discussion_id && resolvedStatusMessage"
      class="review-preview-item-footer draft-note-resolution p-0"
    >
      <icon class="gl-mr-3" name="status_success" /> {{ resolvedStatusMessage }}
    </span>
  </button>
</template>
