(() => {
  const BoardBlankState = Vue.extend({
    methods: {
      addDefaultLists: function () {
        
      },
      clearBlankState: function () {
        BoardsStore.removeList('blank');
      }
    }
  });

  Vue.component('board-blank-state', BoardBlankState);
})();
