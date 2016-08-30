(function() {
  this.ImageFile = (function() {
    var prepareFrames;

    ImageFile.availWidth = 900;

    ImageFile.viewModes = ['two-up', 'swipe'];

    function ImageFile(file) {
      this.file = file;
      this.requestImageInfo($('.two-up.view .frame.deleted img', this.file), (function(_this) {
        return function(deletedWidth, deletedHeight) {
          return _this.requestImageInfo($('.two-up.view .frame.added img', _this.file), function(width, height) {
            if (width === deletedWidth && height === deletedHeight) {
              return _this.initViewModes();
            } else {
              return _this.initView('two-up');
            }
          });
        };
      })(this));
    }

    ImageFile.prototype.initViewModes = function() {
      var viewMode;
      viewMode = ImageFile.viewModes[0];
      $('.view-modes', this.file).removeClass('hide');
      $('.view-modes-menu', this.file).on('click', 'li', (function(_this) {
        return function(event) {
          if (!$(event.currentTarget).hasClass('active')) {
            return _this.activateViewMode(event.currentTarget.className);
          }
        };
      })(this));
      return this.activateViewMode(viewMode);
    };

    ImageFile.prototype.activateViewMode = function(viewMode) {
      $('.view-modes-menu li', this.file).removeClass('active').filter("." + viewMode).addClass('active');
      return $(".view:visible:not(." + viewMode + ")", this.file).fadeOut(200, (function(_this) {
        return function() {
          $(".view." + viewMode, _this.file).fadeIn(200);
          return _this.initView(viewMode);
        };
      })(this));
    };

    ImageFile.prototype.initView = function(viewMode) {
      return this.views[viewMode].call(this);
    };

    prepareFrames = function(view) {
      var maxHeight, maxWidth;
      maxWidth = 0;
      maxHeight = 0;
      $('.frame', view).each((function(_this) {
        return function(index, frame) {
          var height, width;
          width = $(frame).width();
          height = $(frame).height();
          maxWidth = width > maxWidth ? width : maxWidth;
          return maxHeight = height > maxHeight ? height : maxHeight;
        };
      })(this)).css({
        width: maxWidth,
        height: maxHeight
      });
      return [maxWidth, maxHeight];
    };

    ImageFile.prototype.views = {
      'two-up': function() {
        return $('.two-up.view .wrap', this.file).each((function(_this) {
          return function(index, wrap) {
            $('img', wrap).each(function() {
              var currentWidth;
              currentWidth = $(this).width();
              if (currentWidth > ImageFile.availWidth / 2) {
                return $(this).width(ImageFile.availWidth / 2);
              }
            });
            return _this.requestImageInfo($('img', wrap), function(width, height) {
              $('.image-info .meta-width', wrap).text(width + "px");
              $('.image-info .meta-height', wrap).text(height + "px");
              return $('.image-info', wrap).removeClass('hide');
            });
          };
        })(this));
      },
      'swipe': function() {
        var maxHeight, maxWidth;
        maxWidth = 0;
        maxHeight = 0;
        return $('.swipe.view', this.file).each((function(_this) {
          return function(index, view) {
            var ref;
            ref = prepareFrames(view), maxWidth = ref[0], maxHeight = ref[1];
            $('.swipe-frame', view).css({
              width: maxWidth + 16,
              height: maxHeight + 28
            });
            $('.swipe-wrap', view).css({
              width: maxWidth + 1,
              height: maxHeight + 2
            });
            return $('.swipe-bar', view).css({
              left: 0
            }).draggable({
              axis: 'x',
              containment: 'parent',
              drag: function(event) {
                return $('.swipe-wrap', view).width((maxWidth + 1) - $(this).position().left);
              },
              stop: function(event) {
                return $('.swipe-wrap', view).width((maxWidth + 1) - $(this).position().left);
              }
            });
          };
        })(this));
      },
      'onion-skin': function() {
        var dragTrackWidth, maxHeight, maxWidth;
        maxWidth = 0;
        maxHeight = 0;
        dragTrackWidth = $('.drag-track', this.file).width() - $('.dragger', this.file).width();
        return $('.onion-skin.view', this.file).each((function(_this) {
          return function(index, view) {
            var ref;
            ref = prepareFrames(view), maxWidth = ref[0], maxHeight = ref[1];
            $('.onion-skin-frame', view).css({
              width: maxWidth + 16,
              height: maxHeight + 28
            });
            $('.swipe-wrap', view).css({
              width: maxWidth + 1,
              height: maxHeight + 2
            });
            return $('.dragger', view).css({
              left: dragTrackWidth
            }).draggable({
              axis: 'x',
              containment: 'parent',
              drag: function(event) {
                return $('.frame.added', view).css('opacity', $(this).position().left / dragTrackWidth);
              },
              stop: function(event) {
                return $('.frame.added', view).css('opacity', $(this).position().left / dragTrackWidth);
              }
            });
          };
        })(this));
      }
    };

    ImageFile.prototype.requestImageInfo = function(img, callback) {
      var domImg;
      domImg = img.get(0);
      if (domImg) {
        if (domImg.complete) {
          return callback.call(this, domImg.naturalWidth, domImg.naturalHeight);
        } else {
          return img.on('load', (function(_this) {
            return function() {
              return callback.call(_this, domImg.naturalWidth, domImg.naturalHeight);
            };
          })(this));
        }
      }
    };

    return ImageFile;

  })();

}).call(this);
