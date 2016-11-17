/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, consistent-return, one-var, one-var-declaration-per-line, no-undef, prefer-template, padded-blocks, max-len */

/*= require latinise */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Wikis = (function() {
    function Wikis() {
      this.slugify = bind(this.slugify, this);
      $('.new-wiki-page').on('submit', (function(_this) {
        return function(e) {
          var field, path, slug;
          $('[data-error~=slug]').addClass('hidden');
          field = $('#new_wiki_path');
          slug = _this.slugify(field.val());
          if (slug.length > 0) {
            path = field.attr('data-wikis-path');
            location.href = path + '/' + slug;
            return e.preventDefault();
          }
        };
      })(this));
    }

    Wikis.prototype.dasherize = function(value) {
      return value.replace(/[_\s]+/g, '-');
    };

    Wikis.prototype.slugify = function(value) {
      return this.dasherize(value.trim().toLowerCase().latinise());
    };

    return Wikis;

  })();

}).call(this);
