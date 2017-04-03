/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-unused-vars, one-var, no-underscore-dangle, prefer-template, no-else-return, prefer-arrow-callback, max-len */
/* global Api */

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

  this.ProjectNew = (function() {
    function ProjectNew() {
      this.toggleSettings = bind(this.toggleSettings, this);
      this.$selects = $('.project-feature select');
      this.$repoSelects = this.$selects.filter('.js-repo-select');

      $('.project-edit-container').on('ajax:before', (function(_this) {
        return function() {
          $('.project-edit-container').hide();
          return $('.save-project-loader').show();
        };
      })(this));

      this.initVisibilitySelect();

      this.toggleSettings();
      this.toggleSettingsOnclick();
      this.toggleRepoVisibility();

      $('.js-approvers').on('click', this.addApprover.bind(this));
      $(document).on('click', '.js-approver-remove', this.removeApprover.bind(this));

      this.initApproverSelect();
    }

    ProjectNew.prototype.initApproverSelect = function() {
      $('.js-select-user-and-group').select2({
        placeholder: 'Search for users or groups',
        multiple: true,
        minimumInputLength: 0,
        query(query) {
          const groupsApi = Api.groups(query.term, {}, function(groups) {
            return groups;
          });

          const usersApi = Api.users(query.term, {}, function(groups) {
            return groups;
          });

          return $.when(groupsApi, usersApi).then((groups, users) => {
            const data = {
              results: groups[0].concat(users[0]),
            };
            return query.callback(data);
          });
        },
        formatResult: this.formatResult,
        formatSelection: this.formatSelection,
        dropdownCssClass: 'ajax-groups-dropdown',
      })
      .on('change', (evt) => {
        const { added, removed } = evt;
        const groupInput = $('[name="project[approver_group_ids]"]');
        const userInput = $('[name="project[approver_ids]"]');

        if (added) {
          if (added.full_name) {
            groupInput.val(`${groupInput.val()},${added.id}`.replace(/^,/, ''));
          } else {
            userInput.val(`${userInput.val()},${added.id}`.replace(/^,/, ''));
          }
        }

        if (removed) {
          if (removed.full_name) {
            groupInput.val(groupInput.val().replace(new RegExp(`,?${removed.id}`), ''));
          } else {
            userInput.val(userInput.val().replace(new RegExp(`,?${removed.id}`), ''));
          }
        }
      });
    };

    ProjectNew.prototype.formatResult = function(group) {
      if (group.username) {
        return "<div class='group-result'> <div class='group-name'>" + group.name + "</div> <div class='group-path'></div> </div>";
      }

      let avatar;
      if (group.avatar_url) {
        avatar = group.avatar_url;
      } else {
        avatar = gon.default_avatar_url;
      }
      return `
        <div class='group-result'>
          <div class='group-name'>
            ${group.full_name}
          </div>
          <div class='group-path'>
            ${group.full_path}
          </div>
        </div>
      `;
    };

    ProjectNew.prototype.formatSelection = function(group) {
      return group.full_name || group.name;
    };

    ProjectNew.prototype.addApprover = function(evt) {
      const fieldNames = ['project[approver_ids]', 'project[approver_group_ids]'];
      fieldNames.forEach((fieldName) => {
        const $select = $(`[name="${fieldName}"]`);
        const newValue = $select.val();

        if (!newValue) {
          return;
        }

        const $form = $('.js-approvers').closest('form');
        $('.load-wrapper').removeClass('hidden');
        $.ajax({
          url: $form.attr('action'),
          type: 'POST',
          data: {
            _method: 'PATCH',
            [fieldName]: newValue,
          },
          success: this.updateApproverList,
          complete() {
            $select.select2('val', '');
            $('.js-select-user-and-group').select2('val', '');
            $('.load-wrapper').addClass('hidden');
          },
          error(err) {
            // TODO: scroll into view or toast
            window.Flash('Failed to add Approver', 'alert');
          },
        });
      });
    };

    ProjectNew.prototype.removeApprover = function(evt) {
      evt.preventDefault();
      const target = evt.currentTarget;
      $('.load-wrapper').removeClass('hidden');
      $.ajax({
        url: target.getAttribute('href'),
        type: 'POST',
        data: {
          _method: 'DELETE',
        },
        success: this.updateApproverList,
        complete: () => $('.load-wrapper').addClass('hidden'),
        error(err) {
          window.Flash('Failed to remove Approver', 'alert');
        },
      });
    };

    ProjectNew.prototype.updateApproverList = function(html) {
      const fakeEl = document.createElement('template');
      fakeEl.innerHTML = html;
      document.querySelector('.well-list.approver-list').innerHTML = fakeEl.content.querySelector('.well-list.approver-list').innerHTML;
    };

    ProjectNew.prototype.initVisibilitySelect = function() {
      const visibilityContainer = document.querySelector('.js-visibility-select');
      if (!visibilityContainer) return;
      const visibilitySelect = new gl.VisibilitySelect(visibilityContainer);
      visibilitySelect.init();
    };

    ProjectNew.prototype.toggleSettings = function() {
      var self = this;

      this.$selects.each(function () {
        var $select = $(this);
        var className = $select.data('field')
          .replace(/_/g, '-')
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

    ProjectNew.prototype.toggleRepoVisibility = function () {
      var $repoAccessLevel = $('.js-repo-access-level select');
      var containerRegistry = document.querySelectorAll('.js-container-registry')[0];
      var containerRegistryCheckbox = document.getElementById('project_container_registry_enabled');

      this.$repoSelects.find("option[value='" + $repoAccessLevel.val() + "']")
        .nextAll()
        .hide();

      $repoAccessLevel.off('change')
        .on('change', function () {
          var selectedVal = parseInt($repoAccessLevel.val(), 10);

          this.$repoSelects.each(function () {
            var $this = $(this);
            var repoSelectVal = parseInt($this.val(), 10);

            $this.find('option').show();

            if (selectedVal < repoSelectVal) {
              $this.val(selectedVal);
            }

            $this.find("option[value='" + selectedVal + "']").nextAll().hide();
          });

          if (selectedVal) {
            this.$repoSelects.removeClass('disabled');

            if (containerRegistry) {
              containerRegistry.style.display = '';
            }
          } else {
            this.$repoSelects.addClass('disabled');

            if (containerRegistry) {
              containerRegistry.style.display = 'none';
              containerRegistryCheckbox.checked = false;
            }
          }
        }.bind(this));
    };

    return ProjectNew;
  })();
}).call(window);
