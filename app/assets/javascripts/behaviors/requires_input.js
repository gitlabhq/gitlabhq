// Requires Input behavior
//
// When called on a form with input fields with the `required` attribute, the
// form's submit button will be disabled until all required fields have values.
//
/*= require extensions/jquery */

//
// ### Example Markup
//
//   <form class="js-requires-input">
//     <input type="text" required="required">
//     <input type="submit" value="Submit">
//   </form>
//
(function() {
  $.fn.requiresInput = function() {
    var $button, $form, fieldSelector, requireInput, required;
    $form = $(this);
    $button = $('button[type=submit], input[type=submit]', $form);
    required = '[required=required]';
    fieldSelector = "input" + required + ", select" + required + ", textarea" + required;
    requireInput = function() {
      var values;
      values = _.map($(fieldSelector, $form), function(field) {
        // Collect the input values of *all* required fields
        return field.value;
      });
      // Disable the button if any required fields are empty
      if (values.length && _.any(values, _.isEmpty)) {
        return $button.disable();
      } else {
        return $button.enable();
      }
    };
    // Set initial button state
    requireInput();
    return $form.on('change input', fieldSelector, requireInput);
  };

  $(function() {
    var $form, hideOrShowHelpBlock;
    $form = $('form.js-requires-input');
    $form.requiresInput();
    // Hide or Show the help block when creating a new project
    // based on the option selected
    hideOrShowHelpBlock = function(form) {
      var selected;
      selected = $('.js-select-namespace option:selected');
      if (selected.length && selected.data('options-parent') === 'groups') {
        return form.find('.help-block').hide();
      } else if (selected.length) {
        return form.find('.help-block').show();
      }
    };
    hideOrShowHelpBlock($form);
    return $('.select2.js-select-namespace').change(function() {
      return hideOrShowHelpBlock($form);
    });
  });

}).call(this);
