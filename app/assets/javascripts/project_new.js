(function() {
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
      this._showOrHide('#project_project_feature_attributes_builds_access_level', '.builds-feature');
      this._showOrHide('#project_project_feature_attributes_merge_requests_access_level', '.merge-requests-feature');
    };

    ProjectNew.prototype.toggleSettingsOnclick = function() {
      $('#project_project_feature_attributes_builds_access_level, #project_project_feature_attributes_merge_requests_access_level').on('change', this.toggleSettings);
    };

    ProjectNew.prototype._showOrHide = function(checkElement, container) {
      var $container;
      $container = $(container);
      if ($(checkElement).val() !== '0') {
        return $container.show();
      } else {
        return $container.hide();
      }
    };

    return ProjectNew;

  })();

}).call(this);
