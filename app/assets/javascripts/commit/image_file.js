/* eslint-disable func-names, no-var, prefer-arrow-callback, no-else-return, consistent-return, prefer-template, one-var, no-unused-vars, no-return-assign, no-unused-expressions, no-sequences */

import $ from 'jquery';

// Width where images must fits in, for 2-up this gets divided by 2
const availWidth = 900;
const viewModes = ['two-up', 'swipe'];

export default class ImageFile {
  constructor(file) {
    this.file = file;
    this.requestImageInfo(
      $('.two-up.view .frame.deleted img', this.file),
      (function(_this) {
        return function(deletedWidth, deletedHeight) {
          return _this.requestImageInfo($('.two-up.view .frame.added img', _this.file), function(
            width,
            height,
          ) {
            _this.initViewModes();

            // Load two-up view after images are loaded
            // so that we can display the correct width and height information
            const $images = $('.two-up.view img', _this.file);

            $images.waitForImages(function() {
              _this.initView('two-up');
            });
          });
        };
      })(this),
    );
  }

  initViewModes() {
    const viewMode = viewModes[0];
    $('.view-modes', this.file).removeClass('hide');
    $('.view-modes-menu', this.file).on(
      'click',
      'li',
      (function(_this) {
        return function(event) {
          if (!$(event.currentTarget).hasClass('active')) {
            return _this.activateViewMode(event.currentTarget.className);
          }
        };
      })(this),
    );
    return this.activateViewMode(viewMode);
  }

  activateViewMode(viewMode) {
    $('.view-modes-menu li', this.file)
      .removeClass('active')
      .filter('.' + viewMode)
      .addClass('active');
    return $('.view:visible:not(.' + viewMode + ')', this.file).fadeOut(
      200,
      (function(_this) {
        return function() {
          $('.view.' + viewMode, _this.file).fadeIn(200);
          return _this.initView(viewMode);
        };
      })(this),
    );
  }

  initView(viewMode) {
    return this.views[viewMode].call(this);
  }
  // eslint-disable-next-line class-methods-use-this
  initDraggable($el, padding, callback) {
    var dragging = false;
    const $body = $('body');
    const $offsetEl = $el.parent();
    const dragStart = function() {
      dragging = true;
      $body.css('user-select', 'none');
    };
    const dragStop = function() {
      dragging = false;
      $body.css('user-select', '');
    };
    const dragMove = function(e) {
      const moveX = e.pageX || e.touches[0].pageX;
      const left = moveX - ($offsetEl.offset().left + padding);
      if (!dragging) return;

      callback(e, left);
    };

    $el
      .off('mousedown')
      .off('touchstart')
      .on('mousedown', dragStart)
      .on('touchstart', dragStart);

    $body
      .off('mouseup')
      .off('mousemove')
      .off('touchend')
      .off('touchmove')
      .on('mouseup', dragStop)
      .on('touchend', dragStop)
      .on('mousemove', dragMove)
      .on('touchmove', dragMove);
  }

  prepareFrames(view) {
    var maxHeight, maxWidth;
    maxWidth = 0;
    maxHeight = 0;
    $('.frame', view)
      .each(
        (function(_this) {
          return function(index, frame) {
            var height, width;
            width = $(frame).width();
            height = $(frame).height();
            maxWidth = width > maxWidth ? width : maxWidth;
            return (maxHeight = height > maxHeight ? height : maxHeight);
          };
        })(this),
      )
      .css({
        width: maxWidth,
        height: maxHeight,
      });
    return [maxWidth, maxHeight];
  }

  views = {
    'two-up': function() {
      return $('.two-up.view .wrap', this.file).each(
        (function(_this) {
          return function(index, wrap) {
            $('img', wrap).each(function() {
              var currentWidth;
              currentWidth = $(this).width();
              if (currentWidth > availWidth / 2) {
                return $(this).width(availWidth / 2);
              }
            });
            return _this.requestImageInfo($('img', wrap), function(width, height) {
              $('.image-info .meta-width', wrap).text(width + 'px');
              $('.image-info .meta-height', wrap).text(height + 'px');
              return $('.image-info', wrap).removeClass('hide');
            });
          };
        })(this),
      );
    },
    swipe() {
      var maxHeight, maxWidth;
      maxWidth = 0;
      maxHeight = 0;
      return $('.swipe.view', this.file).each(
        (function(_this) {
          return function(index, view) {
            var $swipeWrap, $swipeBar, $swipeFrame, wrapPadding, ref;
            (ref = _this.prepareFrames(view)), ([maxWidth, maxHeight] = ref);
            $swipeFrame = $('.swipe-frame', view);
            $swipeWrap = $('.swipe-wrap', view);
            $swipeBar = $('.swipe-bar', view);

            $swipeFrame.css({
              width: maxWidth + 16,
              height: maxHeight + 28,
            });
            $swipeWrap.css({
              width: maxWidth + 1,
              height: maxHeight + 2,
            });
            // Set swipeBar left position to match image frame
            $swipeBar.css({
              left: 1,
            });

            wrapPadding = parseInt($swipeWrap.css('right').replace('px', ''), 10);

            _this.initDraggable($swipeBar, wrapPadding, function(e, left) {
              if (left > 0 && left < $swipeFrame.width() - wrapPadding * 2) {
                $swipeWrap.width(maxWidth + 1 - left);
                $swipeBar.css('left', left);
              }
            });
          };
        })(this),
      );
    },
    'onion-skin': function() {
      var dragTrackWidth, maxHeight, maxWidth;
      maxWidth = 0;
      maxHeight = 0;
      dragTrackWidth = $('.drag-track', this.file).width() - $('.dragger', this.file).width();
      return $('.onion-skin.view', this.file).each(
        (function(_this) {
          return function(index, view) {
            var $frame,
              $track,
              $dragger,
              $frameAdded,
              framePadding,
              ref,
              dragging = false;
            (ref = _this.prepareFrames(view)), ([maxWidth, maxHeight] = ref);
            $frame = $('.onion-skin-frame', view);
            $frameAdded = $('.frame.added', view);
            $track = $('.drag-track', view);
            $dragger = $('.dragger', $track);

            $frame.css({
              width: maxWidth + 16,
              height: maxHeight + 28,
            });
            $('.swipe-wrap', view).css({
              width: maxWidth + 1,
              height: maxHeight + 2,
            });
            $dragger.css({
              left: dragTrackWidth,
            });

            $frameAdded.css('opacity', 1);
            framePadding = parseInt($frameAdded.css('right').replace('px', ''), 10);

            _this.initDraggable($dragger, framePadding, function(e, left) {
              var opacity = left / dragTrackWidth;

              if (opacity >= 0 && opacity <= 1) {
                $dragger.css('left', left);
                $frameAdded.css('opacity', opacity);
              }
            });
          };
        })(this),
      );
    },
  };

  requestImageInfo(img, callback) {
    const domImg = img.get(0);
    if (domImg) {
      if (domImg.complete) {
        return callback.call(this, domImg.naturalWidth, domImg.naturalHeight);
      } else {
        return img.on(
          'load',
          (function(_this) {
            return function() {
              return callback.call(_this, domImg.naturalWidth, domImg.naturalHeight);
            };
          })(this),
        );
      }
    }
  }
}
