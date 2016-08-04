$(() => {
  $('.js-new-board-list').each(function () {
    const $this = $(this);

    $this.glDropdown({
      data: function(term, callback) {
        $.ajax({
          url: $this.attr('data-labels')
        }).then((resp) => {
          callback(resp);
        });
      },
      renderRow: (label) => {
        const $li = $('<li />'),
              $a = $('<a />', {
                text: label.title,
                href: '#'
              }),
              $labelColor = $('<span />', {
                class: 'dropdown-label-box',
                style: `background-color: ${label.color}`
              });

        return $li.append($a.prepend($labelColor));
      },
			search: {
				fields: ['title']
			},
			filterable: true,
      selectable: true,
      clicked: (label, $el, e) => {
        e.preventDefault();
        BoardsStore.new({
          title: label.title,
          position: BoardsStore.state.lists.length - 1,
          label: {
            id: label.id,
            title: label.title,
            color: label.color
          },
          issues: []
        });
      }
    });
  });
});
