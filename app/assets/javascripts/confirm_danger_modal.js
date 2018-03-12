/* eslint-disable func-names, space-before-function-paren, wrap-iife, one-var, no-var, camelcase, one-var-declaration-per-line, no-else-return, max-len */

import $ from 'jquery';
import { rstrip } from './lib/utils/common_utils';

window.ConfirmDangerModal = (function() {
  function ConfirmDangerModal(form, text) {
    var project_path, submit;
    this.form = form;
    $('.js-confirm-text').text(text || '');
    $('.js-confirm-danger-input').val('');
    $('#modal-confirm-danger').modal('show');
    project_path = $('.js-confirm-danger-match').text();
    submit = $('.js-confirm-danger-submit');
    submit.disable();
    $('.js-confirm-danger-input').off('input');
    $('.js-confirm-danger-input').on('input', function() {
      if (rstrip($(this).val()) === project_path) {
        return submit.enable();
      } else {
        return submit.disable();
      }
    });
    $('.js-confirm-danger-submit').off('click');
    $('.js-confirm-danger-submit').on('click', (function(_this) {
      return function() {
        return _this.form.submit();
      };
    })(this));
  }

  return ConfirmDangerModal;
})();
