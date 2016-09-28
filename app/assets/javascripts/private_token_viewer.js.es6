((global) => {
  gl.PrivateTokenViewer = class PrivateTokenViewer {
    constructor() {
      this.$show = $('#private-token-show');
      this.$error = $('#private-token-error');
      this.$request = $('#private-token-request');
      this.$requestForm = this.$request.find('form');

      this.$requestForm.on('submit', this.submitPassword.bind(this));
    }

    submitPassword(e) {
      e.preventDefault();

      $.ajax({
        url: this.$requestForm.attr('action'),
        method: 'POST',
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify({
          current_password: this.$requestForm.find('#current_password').val()
        })
      }).done((data) => {
        this.$show.find('#token').val(data.private_token);

        this.$show.removeClass('hidden');
        this.$error.addClass('hidden');
        this.$request.addClass('hidden');
      }).error((request) => {
        var message = request.responseJSON && request.responseJSON.message;

        if (!message) {
          message = 'There was an error checking your password. Please try again.';
        }

        this.$error.text(request.responseJSON.message);

        this.$show.addClass('hidden');
        this.$error.removeClass('hidden');
        this.$request.removeClass('hidden');
        this.$requestForm.find('[type="submit"]').enable();
      });
    }
  };
})(window.gl || (window.gl = {}));
