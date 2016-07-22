
/*= require jquery.ba-resize */

/*= require autosize */
$(function() {
  var $fields;
  $fields = $('.js-autosize');
  $fields.on('autosize:resized', function() {
    var $field;
    $field = $(this);
    return $field.data('height', $field.outerHeight());
  });
  $fields.on('resize.autosize', function() {
    var $field;
    $field = $(this);
    if ($field.data('height') !== $field.outerHeight()) {
      $field.data('height', $field.outerHeight());
      autosize.destroy($field);
      return $field.css('max-height', window.outerHeight);
    }
  });
  autosize($fields);
  autosize.update($fields);
  return $fields.css('resize', 'vertical');
});
