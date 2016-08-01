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
      selectable: true,
      clicked: (label, $el, e) => {
        e.preventDefault();
      }
    });
  });
});
