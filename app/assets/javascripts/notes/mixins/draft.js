export default {
  computed: {
    isDraft: () => false,
    canResolve() {
      return this.note.current_user.can_resolve;
    },
  },
};
