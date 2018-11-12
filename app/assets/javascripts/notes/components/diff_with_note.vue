<script>
import { mapState, mapActions } from 'vuex';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import ImageDiffOverlay from '~/diffs/components/image_diff_overlay.vue';
import { GlSkeletonLoading } from '@gitlab-org/gitlab-ui';
import { trimFirstCharOfLineContent, getDiffMode } from '~/diffs/store/utils';

export default {
  components: {
    DiffFileHeader,
    GlSkeletonLoading,
    DiffViewer,
    ImageDiffOverlay,
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
      noteableData: state => state.notes.noteableData,
      projectPath: state => state.diffs.projectPath,
    }),
    diffMode() {
      return getDiffMode(this.diffFile);
    },
    hasTruncatedDiffLines() {
      return this.discussion.truncatedDiffLines && this.discussion.truncatedDiffLines.length !== 0;
    },
    isDiscussionsExpanded() {
      return true; // TODO: @fatihacet - Fix this.
    },
    isCollapsed() {
      return this.diffFile.collapsed || false;
    },
    isImageDiff() {
      return !this.diffFile.text;
    },
    diffFileClass() {
      const { text } = this.diffFile;
      return text ? 'text-file' : 'js-image-file';
    },
    diffFile() {
      return convertObjectPropsToCamelCase(this.discussion.diffFile, { deep: true });
    },
    imageDiffHtml() {
      return this.discussion.imageDiffHtml;
    },
    userColorScheme() {
      return window.gon.user_color_scheme;
    },
    normalizedDiffLines() {
      if (this.discussion.truncatedDiffLines) {
        return this.discussion.truncatedDiffLines.map(line =>
          trimFirstCharOfLineContent(convertObjectPropsToCamelCase(line)),
        );
      }

      return [];
    },
  },
  mounted() {
    if (!this.hasTruncatedDiffLines) {
      this.fetchDiff();
    }
  },
  methods: {
    ...mapActions(['fetchDiscussionDiffLines']),
    rowTag(html) {
      return html.outerHTML ? 'tr' : 'template';
    },
    fetchDiff() {
      this.error = false;
      this.fetchDiscussionDiffLines(this.discussion)
        .then(this.highlight)
        .catch(() => {
          this.error = true;
        });
    },
  },
};
</script>

<template>
  <div
    ref="fileHolder"
    :class="diffFileClass"
    class="diff-file file-holder"
  >
    <diff-file-header
      :discussion-path="discussion.discussionPath"
      :diff-file="diffFile"
      :can-current-user-fork="false"
      :discussions-expanded="isDiscussionsExpanded"
      :expanded="!isCollapsed"
    />
    <div
      v-if="diffFile.text"
      :class="userColorScheme"
      class="diff-content code"
    >
      <table>
        <tr
          v-for="line in normalizedDiffLines"
          :key="line.lineCode"
          class="line_holder"
        >
          <td class="diff-line-num old_line">{{ line.oldLine }}</td>
          <td class="diff-line-num new_line">{{ line.newLine }}</td>
          <td
            :class="line.type"
            class="line_content"
            v-html="line.richText"
          >
          </td>
        </tr>
        <tr
          v-if="!hasTruncatedDiffLines"
          class="line_holder line-holder-placeholder"
        >
          <td class="old_line diff-line-num"></td>
          <td class="new_line diff-line-num"></td>
          <td
            v-if="error"
            class="js-error-lazy-load-diff diff-loading-error-block"
          >
            Unable to load the diff
            <button
              class="btn-link btn-link-retry btn-no-padding js-toggle-lazy-diff-retry-button"
              @click="fetchDiff"
            >
              Try again
            </button>
          </td>
          <td
            v-else
            class="line_content js-success-lazy-load"
          >
            <span></span>
            <gl-skeleton-loading />
            <span></span>
          </td>
        </tr>
        <tr class="notes_holder">
          <td
            class="notes_content"
            colspan="3"
          >
            <slot></slot>
          </td>
        </tr>
      </table>
    </div>
    <div
      v-else
    >
      <diff-viewer
        :diff-mode="diffMode"
        :new-path="diffFile.newPath"
        :new-sha="diffFile.diffRefs.headSha"
        :old-path="diffFile.oldPath"
        :old-sha="diffFile.diffRefs.baseSha"
        :file-hash="diffFile.fileHash"
        :project-path="projectPath"
      >
        <image-diff-overlay
          slot="image-overlay"
          :discussions="discussion"
          :file-hash="diffFile.fileHash"
          :show-comment-icon="true"
          :should-toggle-discussion="false"
          badge-class="image-comment-badge"
        />
      </diff-viewer>
      <slot></slot>
    </div>
  </div>
</template>
