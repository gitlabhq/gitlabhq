<script>
  import syntaxHighlight from '~/syntax_highlight';
  import DiffFileHeader from './diff_file_header.vue';
  import initDiscussionTab from '~/image_diff/init_discussion_tab';
  import imageDiffHelper from '~/image_diff/helpers/index';

  export default {
    props: {
      discussion: {
        type: Object,
        required: true,
      },
    },
    components: {
      DiffFileHeader,
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
        return $(this.discussion.notes[0].truncated_diff_lines);
      },
      diffFile() {
        return this.discussion.notes[0].diff_file || {};
      },
      replacedImageDiffHtml() {
        return this.discussion.notes[0].replaced_image_diff_html;
      },
    },
    mounted() {
      if (this.isImageDiff) {
        const canCreateNote = false;
        const renderCommentBadge = true;
        imageDiffHelper.initImageDiff(this.$refs.fileHolder, canCreateNote, renderCommentBadge);
      } else {
        const fileHolder = $(this.$refs.fileHolder);
        this.$nextTick(() => {
          syntaxHighlight(fileHolder);
        });
      }
    },
  };
</script>

<template>
  <div
    ref="fileHolder"
    class="diff-file file-holder"
    :class="diffFileClass"
  >
    <div class="js-file-title file-title file-title-flex-parent">
      <diff-file-header
        :diff-file="diffFile"
      />
    </div>
    <div
      v-if="diffFile.text"
      class="diff-content code js-syntax-highlight"
    >
      <table>
        <tr
          :class="html.className"
          v-for="html in diffRows"
          v-html="html.outerHTML"
        />
        <tr class="notes_holder">
          <td
            class="notes_line"
            colspan="2"
           />
           <td class="notes_content">
            <slot></slot>
          </td>
        </tr>
      </table>
    </div>
    <div
      v-else
    >
      <div v-html="replacedImageDiffHtml"></div>
      <slot></slot>
    </div>
  </div>
</template>
