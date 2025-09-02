<script>
import { GlBadge, GlSprintf, GlIcon, GlButton } from '@gitlab/ui';
import { mapState } from 'pinia';
import { IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { sprintf, __ } from '~/locale';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
} from '~/notes/components/multiline_comment_utils';
import { useNotes } from '~/notes/store/legacy_notes';
import resolvedStatusMixin from '../mixins/resolved_status';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
    GlButton,
  },
  mixins: [resolvedStatusMixin],
  props: {
    draft: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(useNotes, ['getDiscussion']),
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

      if (file?.file_path) {
        return file.file_path;
      }

      if (this.discussion) {
        return sprintf(
          __("%{authorsName}'s thread"),
          {
            authorsName: this.discussion.notes.find((note) => !note.system).author.name,
          },
          false,
        );
      }

      return __('Your new comment');
    },
    // eslint-disable-next-line vue/no-unused-properties -- linePosition() was used prior to a feature flag removal and may be used again.
    linePosition() {
      if (this.position?.position_type === IMAGE_DIFF_POSITION_TYPE) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        return `${this.position.x}x ${this.position.y}y`;
      }

      return this.position?.new_line || this.position?.old_line;
    },
    content() {
      const el = document.createElement('div');
      // eslint-disable-next-line no-unsanitized/property
      el.innerHTML = this.draft.note_html;

      return el.textContent;
    },
    showLinePosition() {
      return this.draft.file_hash || this.isDiffDiscussion;
    },
    position() {
      return this.draft.position || this.discussion.position;
    },
    startLineNumber() {
      if (this.position?.position_type === IMAGE_DIFF_POSITION_TYPE) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        return `${this.position.x}x ${this.position.y}y`;
      }
      return getStartLineNumber(this.position?.line_range);
    },
    endLineNumber() {
      return getEndLineNumber(this.position?.line_range);
    },
  },
  methods: {
    getLineClasses(lineNumber) {
      return getLineClasses(lineNumber);
    },
  },
  showStaysResolved: false,
};
</script>

<template>
  <div class="pending-review-item gl-relative gl-mb-4 gl-flex gl-gap-3">
    <div
      class="review-comment-icon gl-inline-flex gl-items-center gl-justify-center gl-self-baseline gl-rounded-full gl-bg-strong"
    >
      <gl-icon class="!gl-shrink-0" :name="iconName" :size="14" />
    </div>

    <div class="gl-mt-2 gl-flex gl-flex-col gl-gap-2">
      <gl-button
        variant="link"
        class="!gl-justify-start"
        data-testid="preview-item-header"
        @click="$emit('click', draft)"
      >
        <span class="gl-truncate gl-font-semibold" data-testid="review-preview-item-header-text">{{
          titleText
        }}</span>
        <template v-if="showLinePosition">
          <template v-if="startLineNumber === endLineNumber">
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
      </gl-button>
      <div class="gl-flex gl-flex-col gl-gap-2">
        <p
          class="gl-mb-0 gl-line-clamp-3 gl-leading-20 gl-text-subtle gl-wrap-anywhere"
          data-testid="review-preview-item-content"
        >
          {{ content }}
        </p>
        <gl-badge
          v-if="draft.discussion_id && resolvedStatusMessage"
          class="gl-self-start"
          data-testid="draft-note-resolution"
          variant="info"
          icon="status_success"
          icon-optically-aligned
        >
          {{ resolvedStatusMessage }}
        </gl-badge>
      </div>
    </div>
  </div>
</template>
