/* eslint-disable */
(function() {
  this.ConfirmDangerModal = (function() {
    function ConfirmDangerModal(form, text, arg) {
      var project_path, submit, warningMessage;
      warningMessage = (arg != null ? arg : {}).warningMessage;
      this.form = form;
      $('.js-confirm-text').html(text || '');
      if (warningMessage) {
        $('.js-warning-text').html(warningMessage);
      }
      $('.js-confirm-danger-input').val('');
      $('#modal-confirm-danger').modal('show');
      project_path = $('.js-confirm-danger-match').text();
      submit = $('.js-confirm-danger-submit');
      submit.disable();
      $('.js-confirm-danger-input').off('input');
      $('.js-confirm-danger-input').on('input', function() {
        if (gl.utils.rstrip($(this).val()) === project_path) {
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

}).call(this);
