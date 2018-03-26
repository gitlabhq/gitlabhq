import { mapGetters, mapActions } from 'vuex';
import diffDiscussions from '../components/diff_discussions.vue';
import diffLineGutterContent from '../components/diff_line_gutter_content.vue';
import diffLineNoteForm from '../components/diff_line_note_form.vue';

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
      hoveredLineCode: undefined,
      hoveredSection: undefined,
    };
  },
  components: {
    diffDiscussions,
    diffLineNoteForm,
    diffLineGutterContent,
  },
  computed: {
    ...mapGetters(['discussionsByLineCode']),
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
  },
  methods: {
    ...mapActions(['showCommentForm', 'cancelCommentForm']),
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
    handleShowCommentForm({ lineCode, linePosition }) {
      this.showCommentForm({
        diffLines: this.diffLines,
        lineCode,
        linePosition,
      });
    },
  },
};
