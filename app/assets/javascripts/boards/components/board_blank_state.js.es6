(() => {
  const BoardBlankState = Vue.extend({
    methods: {
      addDefaultLists: function () {

      },
      clearBlankState: function () {
        BoardsStore.removeBlankState();
      }
    }
  });

  Vue.component('board-blank-state', BoardBlankState);
})();
