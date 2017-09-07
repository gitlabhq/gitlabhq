const Store = gl.issueBoards.BoardsStore;

export default {
  template: '#js-board-promotion',
  methods: {
    clearPromotionState: Store.removePromotionState.bind(Store),
  },
};
