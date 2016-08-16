$(() => {
  const Store = gl.issueBoards.BoardsStore;

  $('.js-new-board-list').each(function () {
    const $this = $(this);

    new gl.CreateLabelDropdown($this.closest('.dropdown').find('.dropdown-new-label'), $this.data('project-id'));

    $this.glDropdown({
      data(term, callback) {
        $.ajax({
          url: $this.attr('data-labels')
        }).then((resp) => {
          callback(resp);
        });
      },
      renderRow (label) {
        const active = Store.findList('title', label.title),
              $li = $('<li />',),
              $a = $('<a />', {
                class: (active ? `is-active js-board-list-${active.id}` : ''),
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
      clicked (label, $el, e) {
        e.preventDefault();

        if (!Store.findList('title', label.title)) {
          Store.new({
            title: label.title,
            position: Store.state.lists.length - 2,
            list_type: 'label',
            label: {
              id: label.id,
              title: label.title,
              color: label.color
            }
          });
        }
      }
    });
  });
});
