import $ from 'jquery';
import { isEmpty } from 'lodash';
import '../commons/bootstrap';

// Requires Input behavior
//
// When called on a form with input fields with the `required` attribute, the
// form's submit button will be disabled until all required fields have values.
//
// ### Example Markup
//
//   <form class="js-requires-input">
//     <input type="text" required="required">
//     <input type="submit" value="Submit">
//   </form>
//

$.fn.requiresInput = function requiresInput() {
  const $form = $(this);
  const $button = $('button[type=submit], input[type=submit]', $form);
  const fieldSelector =
    'input[required=required], select[required=required], textarea[required=required]';

  function requireInput() {
    // Collect the input values of *all* required fields
    const values = Array.from($(fieldSelector, $form)).map((field) => field.value);

    // Disable the button if any required fields are empty
    if (values.length && values.some(isEmpty)) {
      $button.disable();
    } else {
      $button.enable();
    }
  }

  // Set initial button state
  requireInput();
  $form.on('change input', fieldSelector, requireInput);
};

$(() => {
  $('form.js-requires-input').each((i, el) => {
    const $form = $(el);
    $form.requiresInput();
  });
});
