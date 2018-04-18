import $ from 'jquery';

// bootstrap jQuery plugins
import 'bootstrap';

// custom jQuery functions
$.fn.extend({
  disable() { return $(this).prop('disabled', true).addClass('disabled'); },
  enable() { return $(this).prop('disabled', false).removeClass('disabled'); },
});
