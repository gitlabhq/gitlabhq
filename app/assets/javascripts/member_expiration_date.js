(function() {
  // Add datepickers to all `js-access-expiration-date` elements. If those elements are
  // children of an element with the `clearable-input` class, and have a sibling
  // `js-clear-input` element, then show that element when there is a value in the
  // datepicker, and make clicking on that element clear the field.
  //
  gl.MemberExpirationDate = function() {
    function toggleClearInput() {
      $(this).closest('.clearable-input').toggleClass('has-value', $(this).val() !== '');
    }

    var inputs = $('.js-access-expiration-date');

    inputs.datepicker({
      dateFormat: 'yy-mm-dd',
      minDate: 1,
      onSelect: toggleClearInput
    });

    inputs.next('.js-clear-input').on('click', function(event) {
      event.preventDefault();

      var input = $(this).closest('.clearable-input').find('.js-access-expiration-date');
      input.datepicker('setDate', null);
      toggleClearInput.call(input);
    });

    inputs.on('blur', toggleClearInput);

    inputs.each(toggleClearInput);
  };
}).call(this);
