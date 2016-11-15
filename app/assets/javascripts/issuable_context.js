/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-new, no-undef, comma-dangle, quotes, prefer-arrow-callback, consistent-return, one-var, no-var, one-var-declaration-per-line, no-underscore-dangle, padded-blocks, max-len */
(function() {
  this.IssuableContext = (function() {
    function IssuableContext(currentUser) {
      this.initParticipants();
      new UsersSelect(currentUser);
      $('select.select2').select2({
        width: 'resolve',
        dropdownAutoWidth: true
      });
      $(".issuable-sidebar .inline-update").on("change", "select", function() {
        return $(this).submit();
      });
      $(".issuable-sidebar .inline-update").on("change", ".js-assignee", function() {
        return $(this).submit();
      });
      $(document).off('click', '.issuable-sidebar .dropdown-content a').on('click', '.issuable-sidebar .dropdown-content a', function(e) {
        return e.preventDefault();
      });
      $(document).off('click', '.edit-link').on('click', '.edit-link', function(e) {
        var $block, $selectbox;
        e.preventDefault();
        $block = $(this).parents('.block');
        $selectbox = $block.find('.selectbox');
        if ($selectbox.is(':visible')) {
          $selectbox.hide();
          $block.find('.value').show();
        } else {
          $selectbox.show();
          $block.find('.value').hide();
        }
        if ($selectbox.is(':visible')) {
          return setTimeout(function() {
            return $block.find('.dropdown-menu-toggle').trigger('click');
          }, 0);
        }
      });
      $(".right-sidebar").niceScroll();
    }

    IssuableContext.prototype.initParticipants = function() {
      var _this;
      _this = this;
      $(document).on("click", ".js-participants-more", this.toggleHiddenParticipants);
      return $(".js-participants-author").each(function(i) {
        if (i >= _this.PARTICIPANTS_ROW_COUNT) {
          return $(this).addClass("js-participants-hidden").hide();
        }
      });
    };

    IssuableContext.prototype.toggleHiddenParticipants = function(e) {
      var currentText, lessText, originalText;
      e.preventDefault();
      currentText = $(this).text().trim();
      lessText = $(this).data("less-text");
      originalText = $(this).data("original-text");
      if (currentText === originalText) {
        $(this).text(lessText);
      } else {
        $(this).text(originalText);
      }
      return $(".js-participants-hidden").toggle();
    };

    return IssuableContext;

  })();

}).call(this);
