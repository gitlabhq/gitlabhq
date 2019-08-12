<script>
/* global Mousetrap */
import 'mousetrap';
import { mapGetters, mapActions } from 'vuex';
import discussionNavigation from '~/notes/mixins/discussion_navigation';

export default {
  mixins: [discussionNavigation],
  props: {
    isDiffView: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      currentDiscussionId: null,
    };
  },
  computed: {
    ...mapGetters(['nextUnresolvedDiscussionId', 'previousUnresolvedDiscussionId']),
  },
  mounted() {
    Mousetrap.bind('n', () => this.jumpToNextDiscussion());
    Mousetrap.bind('p', () => this.jumpToPreviousDiscussion());
  },
  methods: {
    ...mapActions(['expandDiscussion']),
    jumpToNextDiscussion() {
      const nextId = this.nextUnresolvedDiscussionId(this.currentDiscussionId, this.isDiffView);

      this.jumpToDiscussion(nextId);
      this.currentDiscussionId = nextId;
    },
    jumpToPreviousDiscussion() {
      const prevId = this.previousUnresolvedDiscussionId(this.currentDiscussionId, this.isDiffView);

      this.jumpToDiscussion(prevId);
      this.currentDiscussionId = prevId;
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
