(() => {
  const BoardCard = Vue.extend({
    props: {
      issue: Object,
      issueLinkBase: String,
      disabled: Boolean
    },
    methods: {
      filterByLabel: function (label, $event) {
        const labelIndex = BoardsStore.state.filters['label_name'].indexOf(label.title);
        // $($event.target).tooltip('hide');

        if (labelIndex === -1) {
          BoardsStore.state.filters['label_name'].push(label.title);
        } else {
          BoardsStore.state.filters['label_name'].splice(labelIndex, 1);
        }

        BoardsStore.updateFiltersUrl();
      }
    }
  });

  Vue.component('board-card', BoardCard);
})();
