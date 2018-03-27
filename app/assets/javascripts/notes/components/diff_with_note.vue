<script>
import $ from 'jquery';
import syntaxHighlight from '~/syntax_highlight';
import imageDiffHelper from '~/image_diff/helpers/index';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DiffFileHeader from './diff_file_header.vue';

export default {
  components: {
    DiffFileHeader,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isImageDiff() {
      return !this.diffFile.text;
    },
    diffFileClass() {
      const { text } = this.diffFile;
      return text ? 'text-file' : 'js-image-file';
    },
    diffRows() {
      return $(this.discussion.truncatedDiffLines);
    },
    diffFile() {
      return convertObjectPropsToCamelCase(this.discussion.diffFile, {deep: true});
    },
    imageDiffHtml() {
      return this.discussion.imageDiffHtml;
    },
  },
  mounted() {
    if (this.isImageDiff) {
      const canCreateNote = false;
      const renderCommentBadge = true;
      imageDiffHelper.initImageDiff(
        this.$refs.fileHolder,
        canCreateNote,
        renderCommentBadge,
      );
    } else {
      const fileHolder = $(this.$refs.fileHolder);
      this.$nextTick(() => {
        syntaxHighlight(fileHolder);
      });
    }
  },
  methods: {
    rowTag(html) {
      return html.outerHTML ? 'tr' : 'template';
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
    />
    <div
      v-if="diffFile.text"
      class="diff-content code js-syntax-highlight"
    >
      <table>
        <component
          :is="rowTag(html)"
          :class="html.className"
          v-for="(html, index) in diffRows"
          v-html="html.outerHTML"
          :key="index"
        />
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
