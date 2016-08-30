(function() {
  this.Flash = (function() {
    var hideFlash;

    hideFlash = function() {
      return $(this).fadeOut();
    };

    function Flash(message, type, parent) {
      var flash, textDiv;
      if (type == null) {
        type = 'alert';
      }
      if (parent == null) {
        parent = null;
      }
      if (parent) {
        this.flashContainer = parent.find('.flash-container');
      } else {
        this.flashContainer = $('.flash-container-page');
      }
      this.flashContainer.html('');
      flash = $('<div/>', {
        "class": "flash-" + type
      });
      flash.on('click', hideFlash);
      textDiv = $('<div/>', {
        "class": 'flash-text',
        text: message
      });
      textDiv.appendTo(flash);
      if (this.flashContainer.parent().hasClass('content-wrapper')) {
        textDiv.addClass('container-fluid container-limited');
      }
      flash.appendTo(this.flashContainer);
      this.flashContainer.show();
    }

    return Flash;

  })();

}).call(this);
