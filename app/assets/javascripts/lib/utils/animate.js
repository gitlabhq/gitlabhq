/* eslint-disable */
(function() {
  (function(w) {
    if (w.gl == null) {
      w.gl = {};
    }
    if (gl.animate == null) {
      gl.animate = {};
    }
    gl.animate.animate = function($el, animation, options, done) {
      if ((options != null ? options.cssStart : void 0) != null) {
        $el.css(options.cssStart);
      }
      $el.removeClass(animation + ' animated').addClass(animation + ' animated').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() {
        $(this).removeClass(animation + ' animated');
        if (done != null) {
          done();
        }
        if ((options != null ? options.cssEnd : void 0) != null) {
          $el.css(options.cssEnd);
        }
      });
    };
    gl.animate.animateEach = function($els, animation, time, options, done) {
      var dfd;
      dfd = $.Deferred();
      if (!$els.length) {
        dfd.resolve();
      }
      $els.each(function(i) {
        setTimeout((function(_this) {
          return function() {
            var $this;
            $this = $(_this);
            return gl.animate.animate($this, animation, options, function() {
              if (i === $els.length - 1) {
                dfd.resolve();
                if (done != null) {
                  return done();
                }
              }
            });
          };
        })(this), time * i);
      });
      return dfd.promise();
    };
  })(window);

}).call(this);
