import { mapState, mapGetters, mapActions } from 'vuex';
import diffDiscussions from '../components/diff_discussions.vue';
import diffLineGutterContent from '../components/diff_line_gutter_content.vue';
import diffLineNoteForm from '../components/diff_line_note_form.vue';
import { CONTEXT_LINE_TYPE, CONTEXT_LINE_CLASS_NAME } from '../constants';

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
  data() {
    return {
      hoveredLineCode: null,
      hoveredSection: null,
    };
  },
  components: {
    diffDiscussions,
    diffLineNoteForm,
    diffLineGutterContent,
  },
  computed: {
    ...mapState({
      diffLineCommentForms: state => state.diffs.diffLineCommentForms,
    }),
    ...mapGetters(['discussionsByLineCode', 'isLoggedIn']),
    userColorScheme() {
      return window.gon.user_color_scheme;
    },
    normalizedDiffLines() {
      return this.diffLines.map(line => {
        if (line.richText) {
          return this.trimFirstChar(line);
        }

        if (line.left) {
          Object.assign(line, { left: this.trimFirstChar(line.left) });
        }

        if (line.right) {
          Object.assign(line, { right: this.trimFirstChar(line.right) });
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
  methods: {
    ...mapActions(['showCommentForm', 'cancelCommentForm']),
    getRowClass(line) {
      const isContextLine = line.left
        ? line.left.type === CONTEXT_LINE_TYPE
        : line.type === CONTEXT_LINE_TYPE;

      return {
        [line.type]: line.type,
        [CONTEXT_LINE_CLASS_NAME]: isContextLine,
      };
    },
    trimFirstChar(line) {
      if (!line.richText) {
        return line;
      }

      const firstChar = line.richText.charAt(0);

      if (firstChar === ' ' || firstChar === '+' || firstChar === '-') {
        Object.assign(line, {
          richText: line.richText.substring(1),
        });
      }

      return line;
    },
    handleShowCommentForm(params) {
      this.showCommentForm({ lineCode: params.lineCode });
    },
    isDiscussionExpanded(lineCode) {
      const discussions = this.discussionsByLineCode[lineCode];

      return discussions ? discussions.every(discussion => discussion.expanded) : false;
    },
  },
};
