/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, consistent-return, padded-blocks, max-len */
/* global autosize */

/*= require jquery.ba-resize */
/*= require autosize */

(function() {
  $(function() {
    var $fields;
    $fields = $('.js-autosize');
    $fields.off('autosize:resized.setHeight').on('autosize:resized.setHeight', function() {
      var $field;
      $field = $(this);
      return $field.data('height', $field.outerHeight());
    });
    $fields.off('resize.autosize.updateFields').on('resize.autosize.updateFields', function() {
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

}).call(this);
