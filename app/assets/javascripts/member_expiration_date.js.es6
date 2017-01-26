(() => {
  // Add datepickers to all `js-access-expiration-date` elements. If those elements are
  // children of an element with the `clearable-input` class, and have a sibling
  // `js-clear-input` element, then show that element when there is a value in the
  // datepicker, and make clicking on that element clear the field.
  //
  window.gl = window.gl || {};
  gl.MemberExpirationDate = (selector = '.js-access-expiration-date') => {
    function toggleClearInput() {
      $(this).closest('.clearable-input').toggleClass('has-value', $(this).val() !== '');
    }
    const inputs = $(selector);

    inputs.datepicker({
      dateFormat: 'yy-mm-dd',
      minDate: 1,
      onSelect: function onSelect() {
        $(this).trigger('change');
        toggleClearInput.call(this);
      },
    });

    inputs.next('.js-clear-input').on('click', function clicked(event) {
      event.preventDefault();

      const input = $(this).closest('.clearable-input').find(selector);
      input.datepicker('setDate', null)
        .trigger('change');
      toggleClearInput.call(input);
    });

    inputs.on('blur', toggleClearInput);

    inputs.each(toggleClearInput);
  };
}).call(this);
