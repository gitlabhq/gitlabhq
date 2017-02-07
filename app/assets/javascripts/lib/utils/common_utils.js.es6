/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-unused-expressions, no-param-reassign, no-else-return, quotes, object-shorthand, comma-dangle, camelcase, one-var, vars-on-top, one-var-declaration-per-line, no-return-assign, consistent-return, padded-blocks, max-len, prefer-template */
(function() {
  (function(w) {
    var base;
    w.gl || (w.gl = {});
    (base = w.gl).utils || (base.utils = {});
    w.gl.utils.isInGroupsPage = function() {
      return gl.utils.getPagePath() === 'groups';
    };
    w.gl.utils.isInProjectPage = function() {
      return gl.utils.getPagePath() === 'projects';
    };
    w.gl.utils.getProjectSlug = function() {
      if (this.isInProjectPage()) {
        return $('body').data('project');
      } else {
        return null;
      }
    };
    w.gl.utils.getGroupSlug = function() {
      if (this.isInGroupsPage()) {
        return $('body').data('group');
      } else {
        return null;
      }
    };

    w.gl.utils.ajaxGet = function(url) {
      return $.ajax({
        type: "GET",
        url: url,
        dataType: "script"
      });
    };

    w.gl.utils.extractLast = function(term) {
      return this.split(term).pop();
    };

    w.gl.utils.rstrip = function rstrip(val) {
      if (val) {
        return val.replace(/\s+$/, '');
      } else {
        return val;
      }
    };

    w.gl.utils.disableButtonIfEmptyField = function(field_selector, button_selector, event_name) {
      event_name = event_name || 'input';
      var closest_submit, field, that;
      that = this;
      field = $(field_selector);
      closest_submit = field.closest('form').find(button_selector);
      if (this.rstrip(field.val()) === "") {
        closest_submit.disable();
      }
      return field.on(event_name, function() {
        if (that.rstrip($(this).val()) === "") {
          return closest_submit.disable();
        } else {
          return closest_submit.enable();
        }
      });
    };

    // automatically adjust scroll position for hash urls taking the height of the navbar into account
    // https://github.com/twitter/bootstrap/issues/1768
    w.gl.utils.handleLocationHash = function() {
      var hash = w.gl.utils.getLocationHash();
      if (!hash) return;

      // This is required to handle non-unicode characters in hash
      hash = decodeURIComponent(hash);

      var navbar = document.querySelector('.navbar-gitlab');
      var subnav = document.querySelector('.layout-nav');
      var fixedTabs = document.querySelector('.js-tabs-affix');

      var adjustment = 0;
      if (navbar) adjustment -= navbar.offsetHeight;
      if (subnav) adjustment -= subnav.offsetHeight;

      // scroll to user-generated markdown anchor if we cannot find a match
      if (document.getElementById(hash) === null) {
        var target = document.getElementById('user-content-' + hash);
        if (target && target.scrollIntoView) {
          target.scrollIntoView(true);
          window.scrollBy(0, adjustment);
        }
      } else {
        // only adjust for fixedTabs when not targeting user-generated content
        if (fixedTabs) {
          adjustment -= fixedTabs.offsetHeight;
        }
        window.scrollBy(0, adjustment);
      }
    };

    // Check if element scrolled into viewport from above or below
    // Courtesy http://stackoverflow.com/a/7557433/414749
    w.gl.utils.isInViewport = function(el) {
      var rect = el.getBoundingClientRect();

      return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= window.innerHeight &&
        rect.right <= window.innerWidth
      );
    };

    gl.utils.getPagePath = function(index) {
      index = index || 0;
      return $('body').data('page').split(':')[index];
    };

    gl.utils.parseUrl = function (url) {
      var parser = document.createElement('a');
      parser.href = url;
      return parser;
    };

    gl.utils.parseUrlPathname = function (url) {
      var parsedUrl = gl.utils.parseUrl(url);
      // parsedUrl.pathname will return an absolute path for Firefox and a relative path for IE11
      // We have to make sure we always have an absolute path.
      return parsedUrl.pathname.charAt(0) === '/' ? parsedUrl.pathname : '/' + parsedUrl.pathname;
    };

    gl.utils.getUrlParamsArray = function () {
      // We can trust that each param has one & since values containing & will be encoded
      // Remove the first character of search as it is always ?
      return window.location.search.slice(1).split('&');
    };

    gl.utils.isMetaKey = function(e) {
      return e.metaKey || e.ctrlKey || e.altKey || e.shiftKey;
    };

    gl.utils.scrollToElement = function($el) {
      var top = $el.offset().top;
      gl.navBarHeight = gl.navBarHeight || $('.navbar-gitlab').height();
      gl.navLinksHeight = gl.navLinksHeight || $('.nav-links').height();
      gl.mrTabsHeight = gl.mrTabsHeight || $('.merge-request-tabs').height();

      return $('body, html').animate({
        scrollTop: top - (gl.navBarHeight + gl.navLinksHeight + gl.mrTabsHeight)
      }, 200);
    };

    /**
      this will take in the `name` of the param you want to parse in the url
      if the name does not exist this function will return `null`
      otherwise it will return the value of the param key provided
    */
    w.gl.utils.getParameterByName = (name) => {
      const url = window.location.href;
      name = name.replace(/[[\]]/g, '\\$&');
      const regex = new RegExp(`[?&]${name}(=([^&#]*)|&|#|$)`);
      const results = regex.exec(url);
      if (!results) return null;
      if (!results[2]) return '';
      return decodeURIComponent(results[2].replace(/\+/g, ' '));
    };

  })(window);

}).call(this);
