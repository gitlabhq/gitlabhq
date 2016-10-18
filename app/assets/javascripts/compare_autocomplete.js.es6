(function() {
  this.CompareAutocomplete = (function() {
    function CompareAutocomplete() {
      this.initDropdown();
    }

    CompareAutocomplete.prototype.initDropdown = function() {
      return $('.js-compare-dropdown').each(function() {
        var $dropdown, selected;
        $dropdown = $(this);
        selected = $dropdown.data('selected');
        const $dropdownContainer = $dropdown.closest('.dropdown');
        const $fieldInput = $(`input[name="${$dropdown.data('field-name')}"]`, $dropdownContainer);
        const $filterInput = $('input[type="search"]', $dropdownContainer);
        $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: $dropdown.data('refs-url'),
              data: {
                ref: $dropdown.data('ref')
              }
            }).done(function(refs) {
              return callback(refs);
            });
          },
          selectable: true,
          filterable: true,
          filterByText: true,
          toggleLabel: true,
          fieldName: $dropdown.data('field-name'),
          filterInput: 'input[type="search"]',
          renderRow: function(ref) {
            var link;
            if (ref.header != null) {
              return $('<li />').addClass('dropdown-header').text(ref.header);
            } else {
              link = $('<a />').attr('href', '#').addClass(ref === selected ? 'is-active' : '').text(ref).attr('data-ref', escape(ref));
              return $('<li />').append(link);
            }
          },
          id: function(obj, $el) {
            return $el.attr('data-ref');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          }
        });
        $filterInput.on('keyup', (e) => {
          const keyCode = e.keyCode || e.which;
          if (keyCode !== 13) return;
          const text = $filterInput.val();
          $fieldInput.val(text);
          $('.dropdown-toggle-text', $dropdown).text(text);
          $dropdownContainer.removeClass('open');
        });
      });
    };

    return CompareAutocomplete;

  })();

}).call(this);
