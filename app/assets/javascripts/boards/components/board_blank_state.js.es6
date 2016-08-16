(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardBlankState = Vue.extend({
    data () {
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
      addDefaultLists () {
        Store.removeBlankState();

        for (let i = 0, labelsLength = this.predefinedLabels.length; i < labelsLength; i++) {
          const label = this.predefinedLabels[i];

          Store.addList({
            title: label.title,
            position: i,
            list_type: 'label',
            label: {
              title: label.title,
              color: label.color
            }
          });
        }

        // Save the labels
        gl.boardService
          .generateDefaultLists()
          .then((resp) => {
            const data = resp.json();

            for (let i = 0, dataLength = data.length; i < dataLength; i++) {
              const listObj = data[i],
                    list = Store.findList('title', listObj.title);

              list.id = listObj.id;
              list.label.id = listObj.label.id;
              list.getIssues();
            }
          });
      },
      clearBlankState () {
        Store.removeBlankState();
      }
    }
  });
})();
