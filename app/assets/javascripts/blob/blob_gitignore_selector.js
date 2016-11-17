/* eslint-disable func-names, space-before-function-paren, max-len, one-var, no-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, prefer-rest-params, no-undef, padded-blocks, max-len */

/*= require blob/template_selector */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.BlobGitignoreSelector = (function(superClass) {
    extend(BlobGitignoreSelector, superClass);

    function BlobGitignoreSelector() {
      return BlobGitignoreSelector.__super__.constructor.apply(this, arguments);
    }

    BlobGitignoreSelector.prototype.requestFile = function(query) {
      return Api.gitignoreText(query.name, this.requestFileSuccess.bind(this));
    };

    return BlobGitignoreSelector;

  })(gl.TemplateSelector);

}).call(this);
