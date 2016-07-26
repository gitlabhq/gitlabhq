((global) => {
  class UsernameValidator {
    constructor() {
      this.debounceTimeoutDuration = 1000;
      this.errorIconClasses = 'fa fa-exclamation-circle error';
      this.usernameInUseMessage = 'Username "$1" is in use!';
      this.loadingIconClasses = 'fa fa-spinner fa-spin';
      this.successIconClasses = 'fa fa-check-circle success';
      this.tooltipPlacement = 'left';

      this.inputElement = $('#new_user_username');
      this.iconElement  = $('<i></i>');
      this.inputElement.parent().append(this.iconElement);

      let debounceTimeout = _.debounce((username) => {
        this.validateUsername(username);
      }, this.debounceTimeoutDuration);

      this.inputElement.keyup(() => {
        this.iconElement.removeClass().tooltip('destroy');
        let username = this.inputElement.val();
        if (username === '') return;
        this.iconElement.addClass(this.loadingIconClasses);
        debounceTimeout(username);
      });
    }

    validateUsername(username) {
      $.ajax({
        type: 'GET',
        url: `/u/${username}/exists`,
        dataType: 'json',
        success: (res) => {
          if (res.exists) {
            this.iconElement
              .removeClass().addClass(this.errorIconClasses)
              .tooltip({
                title: this.usernameInUseMessage.replace(/\$1/g, username),
                placement: this.tooltipPlacement
              });
          } else {
            this.iconElement
              .removeClass().addClass(this.successIconClasses)
              .tooltip('destroy');
          }
        }
      });
    }
  }

  global.UsernameValidator = UsernameValidator;
})(window);
