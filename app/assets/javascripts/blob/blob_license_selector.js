
/*
//= require blob/template_selector
 */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.BlobLicenseSelector = (function(superClass) {
    extend(BlobLicenseSelector, superClass);

    function BlobLicenseSelector() {
      return BlobLicenseSelector.__super__.constructor.apply(this, arguments);
    }

    BlobLicenseSelector.prototype.requestFile = function(query) {
      var data;
      data = {
        project: this.dropdown.data('project'),
        fullname: this.dropdown.data('fullname')
      };
      return Api.licenseText(query.id, data, this.requestFileSuccess.bind(this));
    };

    return BlobLicenseSelector;

  })(TemplateSelector);

}).call(this);
