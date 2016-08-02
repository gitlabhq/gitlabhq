((global) => {
  const debounceTimeoutDuration = 1000;
  const errorIconClasses = 'fa fa-exclamation-circle error';
  const usernameInUseMessage = 'Username "$1" is in use!';
  const loadingIconClasses = 'fa fa-spinner fa-spin';
  const successIconClasses = 'fa fa-check-circle success';
  const tooltipPlacement = 'left';

  class UsernameValidator {
    constructor() {
      this.inputElement = $('#new_user_username');
      this.iconElement  = $('<i></i>');
      this.inputElement.parent().append(this.iconElement);

      let debounceTimeout = _.debounce((username) => {
        this.validateUsername(username);
      }, debounceTimeoutDuration);

      this.inputElement.keyup(() => {
        this.iconElement.removeClass().tooltip('destroy');
        let username = this.inputElement.val();
        if (username === '') return;
        this.iconElement.addClass(loadingIconClasses);
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
              .removeClass().addClass(errorIconClasses)
              .tooltip({
                title: usernameInUseMessage.replace(/\$1/g, username),
                placement: tooltipPlacement
              });
          } else {
            this.iconElement
              .removeClass().addClass(successIconClasses)
              .tooltip('destroy');
          }
        }
      });
    }
  }

  global.UsernameValidator = UsernameValidator;
})(window);
