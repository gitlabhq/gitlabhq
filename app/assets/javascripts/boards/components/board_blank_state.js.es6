(() => {
  const BoardBlankState = Vue.extend({
    data: function () {
      return {
        predefinedLabels: [
          new Label({ title: 'Development', color: '#5CB85C' }),
          new Label({ title: 'Testing', color: '#F0AD4E' }),
          new Label({ title: 'Production', color: '#FF5F00' }),
          new Label({ title: 'Ready', color: '#FF0000' })
        ]
      }
    },
    methods: {
      addDefaultLists: function () {
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
