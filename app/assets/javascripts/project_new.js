(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.ProjectNew = (function() {
    function ProjectNew() {
      this.toggleSettings = bind(this.toggleSettings, this);
      this.$selects = $('.features select');

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
      var self = this;

      this.$selects.each(function () {
        var $select = $(this),
            className = $select.data('field').replace(/_/g, '-')
              .replace('access-level', 'feature');
        self._showOrHide($select, '.' + className);
      });
    };

    ProjectNew.prototype.toggleSettingsOnclick = function() {
      this.$selects.on('change', this.toggleSettings);
    };

    ProjectNew.prototype._showOrHide = function(checkElement, container) {
      var $container = $(container);

      if ($(checkElement).val() !== '0') {
        return $container.show();
      } else {
        return $container.hide();
      }
    };

    return ProjectNew;

  })();

}).call(this);
