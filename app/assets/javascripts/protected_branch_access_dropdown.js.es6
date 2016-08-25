(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchAccessDropdown = class {
    constructor(options) {
      const { $dropdown, onSelect, onHide, accessLevel, accessLevelsData } = options;
      const self = this;

      this.accessLevel = accessLevel;
      this.accessLevelsData = accessLevelsData;
      this.$dropdown = $dropdown;
      this.$wrap = this.$dropdown.closest(`.${this.accessLevel}-container`);
      this.usersPath = '/autocomplete/users.json';
      this.inputCount = 0;
      this.defaultLabel = this.$dropdown.data('defaultLabel');

      $dropdown.glDropdown({
        selectable: true,
        filterable: true,
        filterRemote: true,
        data: this.getData.bind(this),
        multiSelect: $dropdown.hasClass('js-multiselect'),
        renderRow: this.renderRow.bind(this),
        toggleLabel: this.toggleLabel.bind(this),
        fieldName: this.fieldName.bind(this),
        hidden() {
          // Here because last selected item is not considered after first close
          this.activeIds = self.getActiveIds();

          if (onHide) {
            onHide();
          }
        },
        setActiveIds() {
          // Needed for pre select options
          this.activeIds = self.getActiveIds();
        },
        clicked(item, $el, e) {
          e.preventDefault();
          self.inputCount++;

          if (onSelect) {
            onSelect(item, $el, self);
          }
        }
      });
    }

    toggleLabel(selectedItem, el) {
      let currentItems = this.$dropdown.siblings('.dropdown-menu').find('.is-active');
      let types = _.groupBy(currentItems, (item) => { return item.dataset.type; });
      let label = [];

      if (currentItems.length) {
        Object.keys(types).map((type) => {
          let numberOfTypes = types[type].length;
          let text = numberOfTypes === 1 ? type : `${type}s`;
          label.push(`${numberOfTypes} ${text}`);
        });
      } else {
        label.push(this.defaultLabel);
      }

      return label.join(' and ');
    }

    getData(query, callback) {
      this.getUsers(query).done((response) => {
        let data = this.consolidateData(response);
        callback(data);
      }).error(() => {
        new Flash('Failed to load users.');
      });
    }

    consolidateData(response, callback) {
      let consolidatedData;
      let users = response.map((user) => {
        user.type = 'user';
        return user;
      });
      let mergeAccessLevels = this.accessLevelsData.map((level) => {
        level.type = 'role';
        return level;
      });

      consolidatedData = mergeAccessLevels;

      if (users.length) {
        consolidatedData = mergeAccessLevels.concat(['divider'], users);
      }

      return consolidatedData;
    }

    getUsers(query) {
      return $.ajax({
        dataType: 'json',
        url: this.buildUrl(this.usersPath),
        data: {
          search: query,
          per_page: 20,
          active: true,
          project_id: gon.current_project_id,
          push_code: true,
        }
      });
    }

    buildUrl(url) {
      if (gon.relative_url_root != null) {
        url = gon.relative_url_root.replace(/\/$/, '') + url;
      }
      return url;
    }

    renderRow(item, instance) {
      // Dectect if the current item is already saved so we can add
      // the `is-active` class so the item looks as marked
      const isActive = _.findWhere(instance.activeIds, { id: item.id, type: item.type }) ? 'is-active' : '';
      if (item.type === 'user') {
        return this.userRowHtml(item, isActive);
      } else if (item.type === 'role') {
        return this.roleRowHtml(item, isActive);
      }
    }

    userRowHtml(user, isActive) {
      const  avatarHtml = `<img src='${user.avatar_url}' class='avatar avatar-inline' width='30'>`;
      const  nameHtml = `<strong class='dropdown-menu-user-full-name'>${user.name}</strong>`;
      const  usernameHtml = `<span class='dropdown-menu-user-username'>${user.username}</span>`;
      return `<li><a href='#' class='${isActive ? 'is-active' : ''}' data-type='${user.type}'>${avatarHtml} ${nameHtml} ${usernameHtml}</a></li>`;
    }

    roleRowHtml(role, isActive) {
      return `<li><a href='#' class='${isActive ? 'is-active' : ''}' data-type='${role.type}'>${role.text}</a></li>`;
    }

    fieldName(selectedItem) {
      let fieldName = '';
      let typeToName = {
        role: 'access_level',
        user: 'user_id',
      };
      let $input = this.$wrap.find(`input[data-type][value="${selectedItem.id}"]`);

      if ($input.length) {
        // If input exists return actual name
        fieldName = $input.attr('name');
      } else {
        // If not suggest a name
        fieldName = `protected_branch[${this.accessLevel}_attributes][${this.inputCount}][access_level]`; // Role by default

        if (selectedItem.type === 'user') {
          fieldName = `protected_branch[${this.accessLevel}_attributes][${this.inputCount}][user_id]`;
        }
      }

      return fieldName;
    }

    getActiveIds() {
      let selected = [];
      
      this.$wrap
          .find('input[data-type]')
          .map((i, el) => {
            const $el = $(el);
            selected.push({
              id: parseInt($el.val()),
              type: $el.data('type')
            });
          });

      return selected;
    }
  }

})(window);
