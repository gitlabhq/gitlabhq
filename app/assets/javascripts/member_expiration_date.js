(function() {
  // Add datepickers to all `js-access-expiration-date` elements. If those elements are
  // children of an element with the `clearable-input` class, and have a sibling
  // `js-clear-input` element, then show that element when there is a value in the
  // datepicker, and make clicking on that element clear the field.
  //
  gl.MemberExpirationDate = function() {
    $('.js-access-expiration-date').each(function(i, element) {
      var expirationDateInput = $(element);

      if (expirationDateInput.hasClass('hasDatepicker')) { return; }

      function toggleClearInput() {
        expirationDateInput.closest('.clearable-input').toggleClass('has-value', expirationDateInput.val() !== '');
      }

      expirationDateInput.datepicker({
        dateFormat: 'yy-mm-dd',
        minDate: 1,
        onSelect: toggleClearInput
      });

      expirationDateInput.on('blur', toggleClearInput);

      toggleClearInput();

      expirationDateInput.next('.js-clear-input').on('click', function(event) {
        event.preventDefault();
        expirationDateInput.datepicker('setDate', null);
        toggleClearInput();
      });
    });
  };
}).call(this);
