(function () {
  const BoardCard = Vue.extend({
    props: {
      list: Object,
      issue: Object,
      issueLinkBase: String,
      disabled: Boolean
    },
    methods: {
      filterByLabel: function (label, $event) {
        let labelToggleText = label.title;
        const labelIndex = BoardsStore.state.filters['label_name'].indexOf(label.title);
        $($event.target).tooltip('hide');

        if (labelIndex === -1) {
          BoardsStore.state.filters['label_name'].push(label.title);
          $('.labels-filter').prepend(`<input type="hidden" name="label_name[]" value="${label.title}" />`);
        } else {
          BoardsStore.state.filters['label_name'].splice(labelIndex, 1);
          labelToggleText = BoardsStore.state.filters['label_name'][0];
          $(`.labels-filter input[name="label_name[]"][value="${label.title}"]`).remove();
        }

        const selectedLabels = BoardsStore.state.filters['label_name'];
        if (selectedLabels.length === 0) {
          labelToggleText = 'Label';
        } else if (selectedLabels.length > 1) {
          labelToggleText = `${selectedLabels[0]} + ${selectedLabels.length - 1} more`;
        }

        $('.labels-filter .dropdown-toggle-text').text(labelToggleText);

        BoardsStore.updateFiltersUrl();
      }
    }
  });

  Vue.component('board-card', BoardCard);
})();
