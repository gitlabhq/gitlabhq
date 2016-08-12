(function() {
  this.AwardsHandler = (function() {
    function AwardsHandler() {
      this.aliases = gl.emojiAliases();
      $(document).off('click', '.js-add-award').on('click', '.js-add-award', (function(_this) {
        return function(e) {
          e.stopPropagation();
          e.preventDefault();
          return _this.showEmojiMenu($(e.currentTarget));
        };
      })(this));
      $('html').on('click', function(e) {
        var $target;
        $target = $(e.target);
        if (!$target.closest('.emoji-menu-content').length) {
          $('.js-awards-block.current').removeClass('current');
        }
        if (!$target.closest('.emoji-menu').length) {
          if ($('.emoji-menu').is(':visible')) {
            $('.js-add-award.is-active').removeClass('is-active');
            return $('.emoji-menu').removeClass('is-visible');
          }
        }
      });
      $(document).off('click', '.js-emoji-btn').on('click', '.js-emoji-btn', (function(_this) {
        return function(e) {
          var $target, emoji;
          e.preventDefault();
          $target = $(e.currentTarget);
          emoji = $target.find('.icon').data('emoji');
          $target.closest('.js-awards-block').addClass('current');
          return _this.addAward(_this.getVotesBlock(), _this.getAwardUrl(), emoji);
        };
      })(this));
    }

    AwardsHandler.prototype.showEmojiMenu = function($addBtn) {
      var $holder, $menu, url;
      $menu = $('.emoji-menu');
      if ($addBtn.hasClass('js-note-emoji')) {
        $addBtn.closest('.note').find('.js-awards-block').addClass('current');
      } else {
        $addBtn.closest('.js-awards-block').addClass('current');
      }
      if ($menu.length) {
        $holder = $addBtn.closest('.js-award-holder');
        if ($menu.is('.is-visible')) {
          $addBtn.removeClass('is-active');
          $menu.removeClass('is-visible');
          return $('#emoji_search').blur();
        } else {
          $addBtn.addClass('is-active');
          this.positionMenu($menu, $addBtn);
          $menu.addClass('is-visible');
          return $('#emoji_search').focus();
        }
      } else {
        $addBtn.addClass('is-loading is-active');
        url = this.getAwardMenuUrl();
        return this.createEmojiMenu(url, (function(_this) {
          return function() {
            $addBtn.removeClass('is-loading');
            $menu = $('.emoji-menu');
            _this.positionMenu($menu, $addBtn);
            if (!_this.frequentEmojiBlockRendered) {
              _this.renderFrequentlyUsedBlock();
            }
            return setTimeout(function() {
              $menu.addClass('is-visible');
              $('#emoji_search').focus();
              return _this.setupSearch();
            }, 200);
          };
        })(this));
      }
    };

    AwardsHandler.prototype.createEmojiMenu = function(awardMenuUrl, callback) {
      return $.get(awardMenuUrl, function(response) {
        $('body').append(response);
        return callback();
      });
    };

    AwardsHandler.prototype.positionMenu = function($menu, $addBtn) {
      var css, position;
      position = $addBtn.data('position');
      css = {
        top: ($addBtn.offset().top + $addBtn.outerHeight()) + "px"
      };
      if ((position != null) && position === 'right') {
        css.left = (($addBtn.offset().left - $menu.outerWidth()) + 20) + "px";
        $menu.addClass('is-aligned-right');
      } else {
        css.left = ($addBtn.offset().left) + "px";
        $menu.removeClass('is-aligned-right');
      }
      return $menu.css(css);
    };

    AwardsHandler.prototype.addAward = function(votesBlock, awardUrl, emoji, checkMutuality, callback) {
      if (checkMutuality == null) {
        checkMutuality = true;
      }
      emoji = this.normilizeEmojiName(emoji);
      this.postEmoji(awardUrl, emoji, (function(_this) {
        return function() {
          _this.addAwardToEmojiBar(votesBlock, emoji, checkMutuality);
          return typeof callback === "function" ? callback() : void 0;
        };
      })(this));
      return $('.emoji-menu').removeClass('is-visible');
    };

    AwardsHandler.prototype.addAwardToEmojiBar = function(votesBlock, emoji, checkForMutuality) {
      var $emojiButton, counter;
      if (checkForMutuality == null) {
        checkForMutuality = true;
      }
      if (checkForMutuality) {
        this.checkMutuality(votesBlock, emoji);
      }
      this.addEmojiToFrequentlyUsedList(emoji);
      emoji = this.normilizeEmojiName(emoji);
      $emojiButton = this.findEmojiIcon(votesBlock, emoji).parent();
      if ($emojiButton.length > 0) {
        if (this.isActive($emojiButton)) {
          return this.decrementCounter($emojiButton, emoji);
        } else {
          counter = $emojiButton.find('.js-counter');
          counter.text(parseInt(counter.text()) + 1);
          $emojiButton.addClass('active');
          this.addMeToUserList(votesBlock, emoji);
          return this.animateEmoji($emojiButton);
        }
      } else {
        votesBlock.removeClass('hidden');
        return this.createEmoji(votesBlock, emoji);
      }
    };

    AwardsHandler.prototype.getVotesBlock = function() {
      var currentBlock;
      currentBlock = $('.js-awards-block.current');
      if (currentBlock.length) {
        return currentBlock;
      } else {
        return $('.js-awards-block').eq(0);
      }
    };

    AwardsHandler.prototype.getAwardUrl = function() {
      return this.getVotesBlock().data('award-url');
    };

    AwardsHandler.prototype.checkMutuality = function(votesBlock, emoji) {
      var $emojiButton, awardUrl, isAlreadyVoted, mutualVote;
      awardUrl = this.getAwardUrl();
      if (emoji === 'thumbsup' || emoji === 'thumbsdown') {
        mutualVote = emoji === 'thumbsup' ? 'thumbsdown' : 'thumbsup';
        $emojiButton = votesBlock.find("[data-emoji=" + mutualVote + "]").parent();
        isAlreadyVoted = $emojiButton.hasClass('active');
        if (isAlreadyVoted) {
          this.addAward(votesBlock, awardUrl, mutualVote, false);
        }
      }
    };

    AwardsHandler.prototype.isActive = function($emojiButton) {
      return $emojiButton.hasClass('active');
    };

    AwardsHandler.prototype.decrementCounter = function($emojiButton, emoji) {
      var counter, counterNumber;
      counter = $('.js-counter', $emojiButton);
      counterNumber = parseInt(counter.text(), 10);
      if (counterNumber > 1) {
        counter.text(counterNumber - 1);
        this.removeMeFromUserList($emojiButton, emoji);
      } else if (emoji === 'thumbsup' || emoji === 'thumbsdown') {
        $emojiButton.tooltip('destroy');
        counter.text('0');
        this.removeMeFromUserList($emojiButton, emoji);
        if ($emojiButton.parents('.note').length) {
          this.removeEmoji($emojiButton);
        }
      } else {
        this.removeEmoji($emojiButton);
      }
      return $emojiButton.removeClass('active');
    };

    AwardsHandler.prototype.removeEmoji = function($emojiButton) {
      var $votesBlock;
      $emojiButton.tooltip('destroy');
      $emojiButton.remove();
      $votesBlock = this.getVotesBlock();
      if ($votesBlock.find('.js-emoji-btn').length === 0) {
        return $votesBlock.addClass('hidden');
      }
    };

    AwardsHandler.prototype.getAwardTooltip = function($awardBlock) {
      return $awardBlock.attr('data-original-title') || $awardBlock.attr('data-title') || '';
    };

    AwardsHandler.prototype.removeMeFromUserList = function($emojiButton, emoji) {
      var authors, awardBlock, newAuthors, originalTitle;
      awardBlock = $emojiButton;
      originalTitle = this.getAwardTooltip(awardBlock);
      authors = originalTitle.split(', ');
      authors.splice(authors.indexOf('me'), 1);
      newAuthors = authors.join(', ');
      awardBlock.closest('.js-emoji-btn').removeData('original-title').attr('data-original-title', newAuthors);
      return this.resetTooltip(awardBlock);
    };

    AwardsHandler.prototype.addMeToUserList = function(votesBlock, emoji) {
      var awardBlock, origTitle, users;
      awardBlock = this.findEmojiIcon(votesBlock, emoji).parent();
      origTitle = this.getAwardTooltip(awardBlock);
      users = [];
      if (origTitle) {
        users = origTitle.trim().split(', ');
      }
      users.push('me');
      awardBlock.attr('title', users.join(', '));
      return this.resetTooltip(awardBlock);
    };

    AwardsHandler.prototype.resetTooltip = function(award) {
      var cb;
      award.tooltip('destroy');
      cb = function() {
        return award.tooltip();
      };
      return setTimeout(cb, 200);
    };

    AwardsHandler.prototype.createEmoji_ = function(votesBlock, emoji) {
      var $emojiButton, buttonHtml, emojiCssClass;
      emojiCssClass = this.resolveNameToCssClass(emoji);
      buttonHtml = "<button class='btn award-control js-emoji-btn has-tooltip active' title='me' data-placement='bottom'> <div class='icon emoji-icon " + emojiCssClass + "' data-emoji='" + emoji + "'></div> <span class='award-control-text js-counter'>1</span> </button>";
      $emojiButton = $(buttonHtml);
      $emojiButton.insertBefore(votesBlock.find('.js-award-holder')).find('.emoji-icon').data('emoji', emoji);
      this.animateEmoji($emojiButton);
      $('.award-control').tooltip();
      return votesBlock.removeClass('current');
    };

    AwardsHandler.prototype.animateEmoji = function($emoji) {
      var className;
      className = 'pulse animated';
      $emoji.addClass(className);
      return setTimeout((function() {
        return $emoji.removeClass(className);
      }), 321);
    };

    AwardsHandler.prototype.createEmoji = function(votesBlock, emoji) {
      if ($('.emoji-menu').length) {
        return this.createEmoji_(votesBlock, emoji);
      }
      return this.createEmojiMenu(this.getAwardMenuUrl(), (function(_this) {
        return function() {
          return _this.createEmoji_(votesBlock, emoji);
        };
      })(this));
    };

    AwardsHandler.prototype.getAwardMenuUrl = function() {
      return gon.award_menu_url;
    };

    AwardsHandler.prototype.resolveNameToCssClass = function(emoji) {
      var emojiIcon, unicodeName;
      emojiIcon = $(".emoji-menu-content [data-emoji='" + emoji + "']");
      if (emojiIcon.length > 0) {
        unicodeName = emojiIcon.data('unicode-name');
      } else {
        unicodeName = $(".emoji-menu-content [data-aliases*=':" + emoji + ":']").data('unicode-name');
      }
      return "emoji-" + unicodeName;
    };

    AwardsHandler.prototype.postEmoji = function(awardUrl, emoji, callback) {
      return $.post(awardUrl, {
        name: emoji
      }, function(data) {
        if (data.ok) {
          return callback();
        }
      });
    };

    AwardsHandler.prototype.findEmojiIcon = function(votesBlock, emoji) {
      return votesBlock.find(".js-emoji-btn [data-emoji='" + emoji + "']");
    };

    AwardsHandler.prototype.scrollToAwards = function() {
      var options;
      options = {
        scrollTop: $('.awards').offset().top - 110
      };
      return $('body, html').animate(options, 200);
    };

    AwardsHandler.prototype.normilizeEmojiName = function(emoji) {
      return this.aliases[emoji] || emoji;
    };

    AwardsHandler.prototype.addEmojiToFrequentlyUsedList = function(emoji) {
      var frequentlyUsedEmojis;
      frequentlyUsedEmojis = this.getFrequentlyUsedEmojis();
      frequentlyUsedEmojis.push(emoji);
      return $.cookie('frequently_used_emojis', frequentlyUsedEmojis.join(','), {
        expires: 365
      });
    };

    AwardsHandler.prototype.getFrequentlyUsedEmojis = function() {
      var frequentlyUsedEmojis;
      frequentlyUsedEmojis = ($.cookie('frequently_used_emojis') || '').split(',');
      return _.compact(_.uniq(frequentlyUsedEmojis));
    };

    AwardsHandler.prototype.renderFrequentlyUsedBlock = function() {
      var emoji, frequentlyUsedEmojis, i, len, ul;
      if ($.cookie('frequently_used_emojis')) {
        frequentlyUsedEmojis = this.getFrequentlyUsedEmojis();
        ul = $("<ul class='clearfix emoji-menu-list frequent-emojis'>");
        for (i = 0, len = frequentlyUsedEmojis.length; i < len; i++) {
          emoji = frequentlyUsedEmojis[i];
          $(".emoji-menu-content [data-emoji='" + emoji + "']").closest('li').clone().appendTo(ul);
        }
        $('.emoji-menu-content').prepend(ul).prepend($('<h5>').text('Frequently used'));
      }
      return this.frequentEmojiBlockRendered = true;
    };

    AwardsHandler.prototype.setupSearch = function() {
      return $('input.emoji-search').on('keyup', (function(_this) {
        return function(ev) {
          var found_emojis, h5, term, ul;
          term = $(ev.target).val();
          $('ul.emoji-menu-search, h5.emoji-search').remove();
          if (term) {
            h5 = $('<h5>').text('Search results');
            found_emojis = _this.searchEmojis(term).show();
            ul = $('<ul>').addClass('emoji-menu-list emoji-menu-search').append(found_emojis);
            $('.emoji-menu-content ul, .emoji-menu-content h5').hide();
            return $('.emoji-menu-content').append(h5).append(ul);
          } else {
            return $('.emoji-menu-content').children().show();
          }
        };
      })(this));
    };

    AwardsHandler.prototype.searchEmojis = function(term) {
      return $(".emoji-menu-list:not(.frequent-emojis) [data-emoji*='" + term + "']").closest('li').clone();
    };

    return AwardsHandler;

  })();

}).call(this);
