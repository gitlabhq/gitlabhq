import $ from 'jquery';

// bootstrap jQuery plugins
import 'bootstrap/js/dist/dropdown';
import 'bootstrap/js/dist/tab';

// custom jQuery functions
$.fn.extend({
  disable() {
    return $(this).prop('disabled', true).addClass('disabled');
  },
  enable() {
    return $(this).prop('disabled', false).removeClass('disabled');
  },
});
