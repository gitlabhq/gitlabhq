var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

this.ProjectNew = (function() {
  function ProjectNew() {
    this.toggleSettings = bind(this.toggleSettings, this);
    $('.project-edit-container').on('ajax:before', (function(_this) {
      return function() {
        $('.project-edit-container').hide();
        return $('.save-project-loader').show();
      };
    })(this));
    this.toggleSettings();
    this.toggleSettingsOnclick();
  }

  ProjectNew.prototype.toggleSettings = function() {
    this._showOrHide('#project_builds_enabled', '.builds-feature');
    return this._showOrHide('#project_merge_requests_enabled', '.merge-requests-feature');
  };

  ProjectNew.prototype.toggleSettingsOnclick = function() {
    return $('#project_builds_enabled, #project_merge_requests_enabled').on('click', this.toggleSettings);
  };

  ProjectNew.prototype._showOrHide = function(checkElement, container) {
    var $container;
    $container = $(container);
    if ($(checkElement).prop('checked')) {
      return $container.show();
    } else {
      return $container.hide();
    }
  };

  return ProjectNew;

})();
