<script>
import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { mapState } from 'vuex';
import syntaxHighlight from '~/syntax_highlight';
import imageDiffHelper from '~/image_diff/helpers/index';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';

export default {
  components: {
    DiffFileHeader,
    SkeletonLoadingContainer,
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
    }),
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
    currentUser() {
      return this.noteableData.current_user;
    },
  },
  mounted() {
    if (this.isImageDiff) {
      const canCreateNote = false;
      const renderCommentBadge = true;
      imageDiffHelper.initImageDiff(this.$refs.fileHolder, canCreateNote, renderCommentBadge);
    } else if (this.discussion.truncatedDiffLines.length === 0) {
      this.fetchDiff();
    } else {
      this.highlight();
    }
  },
  methods: {
    rowTag(html) {
      return html.outerHTML ? 'tr' : 'template';
    },
    fetchDiff() {
      this.error = false;
      axios
        .get(this.discussion.truncatedDiffLinesPath)
        .then(({ data }) => {
          this.$set(this.discussion, 'truncatedDiffLines', data.truncated_diff_lines);
        })
        .then(this.highlight)
        .catch(() => {
          this.error = true;
        });
    },
    highlight() {
      const fileHolder = $(this.$refs.fileHolder);
      this.$nextTick(() => {
        syntaxHighlight(fileHolder);
      });
    },
  },
};
</script>

<template>
  <div
    ref="fileHolder"
    class="diff-file file-holder"
    :class="diffFileClass"
  >
    <diff-file-header
      :diff-file="diffFile"
      :current-user="currentUser"
      :discussions-expanded="isDiscussionsExpanded"
      :expanded="!isCollapsed"
    />
    <div
      v-if="diffFile.text"
      class="diff-content code js-syntax-highlight"
    >
      <table>
        <tr
          v-for="line in discussion.truncatedDiffLines"
          :key="line.lineCode"
          class="line_holder"
        >
          <td class="diff-line-num old_line">{{ line.old_line }}</td>
          <td class="diff-line-num new_line">{{ line.new_line }}</td>
          <td
            :class="line.type"
            class="line_content"
            v-html="line.rich_text"
          >
          </td>
        </tr>
        <tr
          v-if="discussion.truncatedDiffLines.length === 0"
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
              @click="fetchDiff"
              class="btn-link btn-link-retry btn-no-padding js-toggle-lazy-diff-retry-button"
            >
              Try again
            </button>
          </td>
          <td
            v-else
            class="line_content js-success-lazy-load"
          >
            <span></span>
            <skeleton-loading-container />
            <span></span>
          </td>
        </tr>
        <tr class="notes_holder">
          <td
            class="notes_line"
            colspan="2"
          ></td>
          <td class="notes_content">
            <slot></slot>
          </td>
        </tr>
      </table>
    </div>
    <div
      v-else
    >
      <div v-html="imageDiffHtml"></div>
      <slot></slot>
    </div>
  </div>
</template>
