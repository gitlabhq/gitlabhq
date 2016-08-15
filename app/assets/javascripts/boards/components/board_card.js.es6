(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardCard = Vue.extend({
    props: {
      list: Object,
      issue: Object,
      issueLinkBase: String,
      disabled: Boolean
    },
    methods: {
      filterByLabel (label, e) {
        let labelToggleText = label.title;
        const labelIndex = gl.issueBoards.BoardsStore.state.filters['label_name'].indexOf(label.title);
        $(e.target).tooltip('hide');

        if (labelIndex === -1) {
          gl.issueBoards.BoardsStore.state.filters['label_name'].push(label.title);
          $('.labels-filter').prepend(`<input type="hidden" name="label_name[]" value="${label.title}" />`);
        } else {
          gl.issueBoards.BoardsStore.state.filters['label_name'].splice(labelIndex, 1);
          labelToggleText = gl.issueBoards.BoardsStore.state.filters['label_name'][0];
          $(`.labels-filter input[name="label_name[]"][value="${label.title}"]`).remove();
        }

        const selectedLabels = gl.issueBoards.BoardsStore.state.filters['label_name'];
        if (selectedLabels.length === 0) {
          labelToggleText = 'Label';
        } else if (selectedLabels.length > 1) {
          labelToggleText = `${selectedLabels[0]} + ${selectedLabels.length - 1} more`;
        }

        $('.labels-filter .dropdown-toggle-text').text(labelToggleText);

        gl.issueBoards.BoardsStore.updateFiltersUrl();
      }
    }
  });
})();
