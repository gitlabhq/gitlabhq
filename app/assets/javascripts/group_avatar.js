/* eslint-disable func-names, space-before-function-paren, wrap-iife, quotes, no-var, one-var, one-var-declaration-per-line, no-useless-escape, max-len */
(function() {
  this.GroupAvatar = (function() {
    function GroupAvatar() {
      $('.js-choose-group-avatar-button').on("click", function() {
        var form;
        form = $(this).closest("form");
        return form.find(".js-group-avatar-input").click();
      });
      $('.js-group-avatar-input').on("change", function() {
        var filename, form;
        form = $(this).closest("form");
        filename = $(this).val().replace(/^.*[\\\/]/, '');
        return form.find(".js-avatar-filename").text(filename);
      });
    }

    return GroupAvatar;
  })();
}).call(window);
