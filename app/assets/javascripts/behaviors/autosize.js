import autosize from 'vendor/autosize';

$(() => {
  const $fields = $('.js-autosize');

  $fields.on('autosize:resized', function resized() {
    const $field = $(this);
    $field.data('height', $field.outerHeight());
  });

  $fields.on('resize.autosize', function resize() {
    const $field = $(this);
    if ($field.data('height') !== $field.outerHeight()) {
      $field.data('height', $field.outerHeight());
      autosize.destroy($field);
      $field.css('max-height', window.outerHeight);
    }
  });

  autosize($fields);
  autosize.update($fields);
  $fields.css('resize', 'vertical');
});
