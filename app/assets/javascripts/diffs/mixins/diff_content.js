import { mapGetters } from 'vuex';
import diffDiscussions from '../components/diff_discussions.vue';
import diffLineGutterContent from '../components/diff_line_gutter_content.vue';
import diffLineNoteForm from '../components/diff_line_note_form.vue';
import diffTableRow from '../components/diff_table_row.vue';
import { trimFirstCharOfLineContent } from '../store/utils';

export default {
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
  },
  components: {
    diffDiscussions,
    diffTableRow,
    diffLineNoteForm,
    diffLineGutterContent,
  },
  computed: {
    ...mapGetters(['commit']),
    commitId() {
      return this.commit && this.commit.id;
    },
    userColorScheme() {
      return window.gon.user_color_scheme;
    },
    normalizedDiffLines() {
      return this.diffLines.map(line => {
        if (line.richText) {
          return trimFirstCharOfLineContent(line);
        }

        if (line.left) {
          Object.assign(line, { left: trimFirstCharOfLineContent(line.left) });
        }

        if (line.right) {
          Object.assign(line, { right: trimFirstCharOfLineContent(line.right) });
        }

        return line;
      });
    },
    diffLinesLength() {
      return this.normalizedDiffLines.length;
    },
    fileHash() {
      return this.diffFile.fileHash;
    },
  },
};
