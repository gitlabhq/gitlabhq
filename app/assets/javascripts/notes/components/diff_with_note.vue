<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import ImageDiffOverlay from '~/diffs/components/image_diff_overlay.vue';
import { getDiffMode } from '~/diffs/store/utils';
import { diffViewerModes } from '~/ide/constants';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import { isCollapsed } from '~/diffs/utils/diff_file';
import { FILE_DIFF_POSITION_TYPE, IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';

const FIRST_CHAR_REGEX = /^(\+|-| )/;

export default {
  components: {
    DiffFileHeader,
    GlSkeletonLoader,
    DiffViewer,
    ImageDiffOverlay,
    GlButton,
  },
  directives: {
    SafeHtml,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      error: false,
    };
  },
  computed: {
    ...mapState({
      projectPath: (state) => state.diffs.projectPath,
    }),
    diffMode() {
      return getDiffMode(this.discussion.diff_file);
    },
    diffViewerMode() {
      return this.discussion.diff_file?.viewer.name;
    },
    fileDiffRefs() {
      return this.discussion.diff_file.diff_refs;
    },
    headSha() {
      return (this.fileDiffRefs ? this.fileDiffRefs.head_sha : this.discussion.commit_id) || '';
    },
    baseSha() {
      return (this.fileDiffRefs ? this.fileDiffRefs.base_sha : this.discussion.commit_id) || '';
    },
    isTextFile() {
      return this.diffViewerMode === diffViewerModes.text;
    },
    hasTruncatedDiffLines() {
      return (
        this.discussion.truncated_diff_lines && this.discussion.truncated_diff_lines.length !== 0
      );
    },
    isCollapsed() {
      return isCollapsed(this.discussion.diff_file);
    },
    positionType() {
      return this.discussion.position?.position_type;
    },
    isFileDiscussion() {
      if (!this.discussion.diff_file) {
        return (
          this.discussion.original_position.position_type === IMAGE_DIFF_POSITION_TYPE ||
          this.discussion.original_position.position_type === FILE_DIFF_POSITION_TYPE
        );
      }

      return this.positionType === FILE_DIFF_POSITION_TYPE;
    },
    showHeader() {
      if (this.discussion.diff_file) return true;

      return (
        this.discussion.original_position.position_type === FILE_DIFF_POSITION_TYPE ||
        this.discussion.original_position.position_type === IMAGE_DIFF_POSITION_TYPE
      );
    },
    backfilledDiffFile() {
      /*
       * https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19118
       *
       * For the vast majority of cases, this should just be discussion.diff_file,
       * but due to that defect, there are potentially some file discussions that cannot
       * be rendered because there is no diff file attached
       *
       * This allows the header to display (sans file mode change) to roughly simulate
       * having an actual diff file.
       */
      return (
        this.discussion.diff_file || {
          file_path: this.discussion.original_position.new_path,
        }
      );
    },
  },
  mounted() {
    if (this.isTextFile && !this.hasTruncatedDiffLines) {
      this.fetchDiff();
    }
  },
  methods: {
    ...mapActions(['fetchDiscussionDiffLines']),
    fetchDiff() {
      this.error = false;
      this.fetchDiscussionDiffLines(this.discussion)
        .then(this.highlight)
        .catch(() => {
          this.error = true;
        });
    },
    trimChar(line) {
      return line.replace(FIRST_CHAR_REGEX, '');
    },
  },
  userColorSchemeClass: window.gon.user_color_scheme,
};
</script>

<template>
  <div :class="{ 'text-file': isTextFile }" class="diff-file file-holder">
    <diff-file-header
      v-if="showHeader"
      :discussion-path="discussion.discussion_path"
      :diff-file="backfilledDiffFile"
      :can-current-user-fork="false"
      class="gl-border gl-border-section"
      :expanded="!isCollapsed"
    />
    <div v-if="isTextFile" class="diff-content">
      <table class="code js-syntax-highlight" :class="$options.userColorSchemeClass">
        <template v-if="!isFileDiscussion">
          <template v-if="hasTruncatedDiffLines">
            <tr
              v-for="line in discussion.truncated_diff_lines"
              v-once
              :key="line.line_code"
              class="line_holder"
            >
              <td :class="line.type" class="diff-line-num old_line">{{ line.old_line }}</td>
              <td :class="line.type" class="diff-line-num new_line">{{ line.new_line }}</td>
              <td
                v-safe-html="trimChar(line.rich_text)"
                :class="line.type"
                class="line_content"
              ></td>
            </tr>
          </template>
          <tr v-if="!hasTruncatedDiffLines" class="line_holder line-holder-placeholder">
            <td class="old_line diff-line-num"></td>
            <td class="new_line diff-line-num"></td>
            <td v-if="error" class="js-error-lazy-load-diff diff-loading-error-block">
              {{ __('Unable to load the diff') }}
              <gl-button
                class="js-toggle-lazy-diff-retry-button gl-font-regular"
                @click="fetchDiff"
              >
                {{ __('Try again') }}
              </gl-button>
            </td>
            <td v-else class="line_content js-success-lazy-load">
              <span></span>
              <gl-skeleton-loader />
              <span></span>
            </td>
          </tr>
        </template>
        <tr class="notes_holder">
          <td :class="{ '!gl-border-t-0': isFileDiscussion }" class="notes-content" colspan="3">
            <slot></slot>
          </td>
        </tr>
      </table>
    </div>
    <div v-else class="diff-content">
      <diff-viewer
        v-if="!isFileDiscussion"
        :diff-file="discussion.diff_file"
        :diff-mode="diffMode"
        :diff-viewer-mode="diffViewerMode"
        :new-path="discussion.diff_file.new_path"
        :new-sha="headSha"
        :old-path="discussion.diff_file.old_path"
        :old-sha="baseSha"
        :file-hash="discussion.diff_file.file_hash"
        :project-path="projectPath"
      >
        <template #image-overlay="{ renderedWidth, renderedHeight }">
          <image-diff-overlay
            v-if="renderedWidth"
            :rendered-width="renderedWidth"
            :rendered-height="renderedHeight"
            :discussions="discussion"
            :file-hash="discussion.diff_file.file_hash"
            :show-comment-icon="true"
            :should-toggle-discussion="false"
            badge-class="image-comment-badge gl-text-purple-500 gl-bg-white gl-rounded-full gl-border-white gl-border-1 gl-border-solid gl-pointer-events-none gl-shadow-md"
          />
        </template>
      </diff-viewer>
      <slot></slot>
    </div>
  </div>
</template>
