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
    ...mapGetters([
      'nextUnresolvedDiscussionId',
      'previousUnresolvedDiscussionId',
      'getDiscussion',
    ]),
  },
  mounted() {
    Mousetrap.bind('n', () => this.jumpToNextDiscussion());
    Mousetrap.bind('p', () => this.jumpToPreviousDiscussion());
  },
  beforeDestroy() {
    Mousetrap.unbind('n');
    Mousetrap.unbind('p');
  },
  methods: {
    ...mapActions(['expandDiscussion']),
    jumpToNextDiscussion() {
      const nextId = this.nextUnresolvedDiscussionId(this.currentDiscussionId, this.isDiffView);
      const nextDiscussion = this.getDiscussion(nextId);
      this.jumpToDiscussion(nextDiscussion);
      this.currentDiscussionId = nextId;
    },
    jumpToPreviousDiscussion() {
      const prevId = this.previousUnresolvedDiscussionId(this.currentDiscussionId, this.isDiffView);
      const prevDiscussion = this.getDiscussion(prevId);
      this.jumpToDiscussion(prevDiscussion);
      this.currentDiscussionId = prevId;
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
