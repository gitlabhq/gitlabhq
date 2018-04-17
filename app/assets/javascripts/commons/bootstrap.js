import $ from 'jquery';

import Popper from 'popper.js/dist/umd/popper';

// bootstrap jQuery plugins
import 'bootstrap/dist/js/bootstrap.bundle';

// custom jQuery functions
$.fn.extend({
  disable() { return $(this).prop('disabled', true).addClass('disabled'); },
  enable() { return $(this).prop('disabled', false).removeClass('disabled'); },
});

// Enable Bootstrap tooltips
$('[data-toggle="tooltip"]').tooltip();
