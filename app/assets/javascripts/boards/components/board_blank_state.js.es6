/* eslint-disable */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardBlankState = Vue.extend({
    data () {
      return {
        predefinedLabels: [
          new ListLabel({ title: 'To Do', color: '#F0AD4E' }),
          new ListLabel({ title: 'Doing', color: '#5CB85C' })
        ]
      }
    },
    methods: {
      addDefaultLists () {
        this.clearBlankState();

        this.predefinedLabels.forEach((label, i) => {
          Store.addList({
            title: label.title,
            position: i,
            list_type: 'label',
            label: {
              title: label.title,
              color: label.color
            }
          });
        });

        Store.state.lists = _.sortBy(Store.state.lists, 'position');

        // Save the labels
        gl.boardService.generateDefaultLists()
          .then((resp) => {
            resp.json().forEach((listObj) => {
              const list = Store.findList('title', listObj.title);

              list.id = listObj.id;
              list.label.id = listObj.label.id;
              list.getIssues();
            });
          });
      },
      clearBlankState: Store.removeBlankState.bind(Store)
    }
  });
})();
