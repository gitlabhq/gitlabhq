<script>
  import mock from './mockdata';
  import DiffFileHeader from './diff_file_header.vue';

  const diffFile = {
    submodule: false,
    submoduleLink: '<a href="/bha">Submodule</a>', // submodule_link(blob, diff_file.content_sha, diff_file.repository)
    discussionPath: '/something',
    renamedFile: false,
    deletedFile: false,
    modeChanged: false,
    aMode: '100755',
    bMode: '100644',
    filePath: 'some/file/path.rb',
    oldPath: '',
    newPath: '',
    fileTypeIcon: 'fa-file-image-o', // file_type_icon_class('file', diff_file.b_mode, diff_file.file_path)
  };

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
    data() {
      return {
        mock,
        diffFile,
      };
    },
    computed: {
      diffFileClass() {
        const { text } = this.discussion.diff_file || {};
        return 'text-file';
        return text ? 'text-file' : 'js-image-file';
      },
      mockData() {
        const $rows = $(this.mock);
        const els = [];
        $rows.each((index, $row) => {
          els.push($row);
        });
        return els;
      }
    },
    mounted() {
      const fileHolder = $(this.$refs.fileHolder);
      this.$nextTick(() => {
        fileHolder.syntaxHighlight();
      });
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
    <div class="diff-content code js-syntax-highlight">
      <table>
        <tr
          :class="html.className"
          v-for="html in mockData"
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
  </div>
</template>
