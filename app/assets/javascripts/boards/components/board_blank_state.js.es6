(() => {
  const BoardBlankState = Vue.extend({
    data: function () {
      return {
        predefinedLabels: [
          new ListLabel({ title: 'Development', color: '#5CB85C' }),
          new ListLabel({ title: 'Testing', color: '#F0AD4E' }),
          new ListLabel({ title: 'Production', color: '#FF5F00' }),
          new ListLabel({ title: 'Ready', color: '#FF0000' })
        ]
      }
    },
    methods: {
      addDefaultLists: function (e) {
        e.stopImmediatePropagation();
        BoardsStore.removeBlankState();

        _.each(this.predefinedLabels, (label, i) => {
          BoardsStore.addList({
            title: label.title,
            position: i,
            type: 'label',
            label: {
              title: label.title,
              color: label.color
            }
          });
        });

        // Save the labels
        gl.boardService
          .generateDefaultLists()
          .then((resp) => {
            const data = resp.json();

            _.each(data, (listObj) => {
              const list = BoardsStore.findList('title', listObj.title);
              list.id = listObj.id;
              list.label.id = listObj.label.id;
              list.getIssues();
            });
          });
      },
      clearBlankState: function () {
        BoardsStore.removeBlankState();
      }
    }
  });

  Vue.component('board-blank-state', BoardBlankState);
})();
