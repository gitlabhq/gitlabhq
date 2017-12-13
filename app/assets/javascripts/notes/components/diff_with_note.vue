<script>
  import mock from './mockdata';
  import DiffFileHeader from './diff_file_header.vue';

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
      <diff-file-header />
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
