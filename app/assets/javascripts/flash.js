/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, one-var, one-var-declaration-per-line, no-param-reassign, quotes, quote-props, prefer-template, comma-dangle, max-len */

window.Flash = (function() {
  var hideFlash;

  hideFlash = function() {
    return $(this).fadeOut();
  };

  /**
   * Flash banner supports different types of Flash configurations
   * along with ability to provide actionConfig which can be used to show
   * additional action or link on banner next to message
   *
   * @param {String} message Flash message
   * @param {String} type Type of Flash, it can be `notice` or `alert` (default)
   * @param {Object} parent Reference to Parent element under which Flash needs to appear
   * @param {Object} actionConfig Map of config to show action on banner
   *    @param {String} href URL to which action link should point (default '#')
   *    @param {String} title Title of action
   *    @param {Function} clickHandler Method to call when action is clicked on
   */
  function Flash(message, type, parent, actionConfig) {
    var flash, textDiv, actionLink;
    if (type == null) {
      type = 'alert';
    }
    if (parent == null) {
      parent = null;
    }
    if (parent) {
      const $parent = $(parent);
      this.flashContainer = $parent.find('.flash-container');
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

    if (actionConfig) {
      const actionLinkConfig = {
        class: 'flash-action',
        href: actionConfig.href || '#',
        text: actionConfig.title
      };

      if (!actionConfig.href) {
        actionLinkConfig.role = 'button';
      }

      actionLink = $('<a/>', actionLinkConfig);

      actionLink.appendTo(flash);
      this.flashContainer.on('click', '.flash-action', actionConfig.clickHandler);
    }
    if (this.flashContainer.parent().hasClass('content-wrapper')) {
      textDiv.addClass('container-fluid container-limited');
    }
    flash.appendTo(this.flashContainer);
    this.flashContainer.show();
  }

  Flash.prototype.destroy = function() {
    this.flashContainer.html('');
  };

  return Flash;
})();
