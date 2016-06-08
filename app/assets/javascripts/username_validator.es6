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
      let inputContainer = this.inputElement.parent();
      inputContainer.append('<i></i>');
      this.iconElement = $('i', inputContainer);

      let debounceTimeout = _.debounce(this.validateUsername, debounceTimeoutDuration);
      this.inputElement.keyup(() => this.debounceRequest(debounceTimeout));
    }

    debounceRequest(debounceTimeout) {
      this.iconElement.removeClass().tooltip('destroy');
      let username = this.inputElement.val();
      if (username === '') return;
      this.iconElement.addClass(loadingIconClasses);
      debounceTimeout(username);
    }

    validateUsername(username) {
      $.ajax({
        type: 'GET',
        url: `/u/${username}/exists`,
        dataType: 'json',
        success: () => {
          this.iconElement
            .removeClass().addClass(errorIconClasses)
            .tooltip({
              title: usernameInUseMessage.replace(/\$1/g, username),
              placement: tooltipPlacement
            });
        },
        error: () => {
          this.iconElement
            .removeClass().addClass(successIconClasses)
            .tooltip('destroy')
        }
      });
    }
  }

  global.UsernameValidator = UsernameValidator;
})(window);
