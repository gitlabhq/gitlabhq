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

      const debounceTimeout = _.debounce((username) => {
        this.validateUsername(username);
      }, debounceTimeoutDuration);

      this.inputElement.keyup(() => {
        this.iconElement.removeClass();
        const username = this.inputElement.val();
        if (username === '') return;
        debounceTimeout(username);
      });
    }

    validateUsername(username) {
      this.iconElement.addClass(loadingIconClasses);
      $.ajax({
        type: 'GET',
        url: `/u/${username}/exists`,
        dataType: 'json',
        success: (res) => {
          this.iconElement.removeClass();
          if (res.exists) this.inputElement.addClass('validation-error');
        }
      });
    }
  }

  global.UsernameValidator = UsernameValidator;
})(window);
