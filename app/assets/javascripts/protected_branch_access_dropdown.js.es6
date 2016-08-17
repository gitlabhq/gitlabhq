(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchAccessDropdown = class {
    constructor(options) {
      const { $dropdown, data, onSelect } = options;
      const self = this;

      this.$dropdown = $dropdown;
      this.usersPath = '/autocomplete/users.json';
      this.inputCount = 0;

      $dropdown.glDropdown({
        selectable: true,
        filterable: true,
        filterRemote: true,
        inputId: $dropdown.data('input-id'),
        data: this.getData.bind(this),
        multiSelect: $dropdown.hasClass('js-multiselect'),
        renderRow: this.renderRow.bind(this),
        toggleLabel: this.toggleLabel.bind(this),
        fieldName: this.fieldName.bind(this),
        setActiveIds() {
          this.activeIds = self.getActiveIds();
        },
        clicked(item, $el, e) {
          e.preventDefault();
          self.inputCount++;
          onSelect();
          return;
        }
      });
    }

    fieldName() {
      throw new Error('No fieldName method defined');
    }

    toggleLabel(selectedItem, el) {
      let currentItems = this.$dropdown.siblings('.dropdown-menu').find('.is-active');
      let types = _.groupBy(currentItems, (item) => { return item.dataset.type; });
      let label = [];

      _.allKeys(types).map((type) => {
        label.push(`${types[type].length} ${type}`);
      });

      return label.join(' and ');
    }

    getData(query, callback) {
      this.getUsers(query).done((response) => {
        let data = this.consolidateData(response);
        callback(data);
      });
    }

    consolidateData(response, callback) {
      let consolidatedData;

      // This probably should come from the backend already formatted
      let users = response.map((user) => {
        user.type = 'user';
        return user;
      });

      let mergeAccessLevels = gon.merge_access_levels.map((level) => {
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
      if (item.type === 'user') {
        return this.userRowHtml(item);
      } else if (item.type === 'role') {
        return this.roleRowHtml(item);
      }
    }

    userRowHtml(user) {
      const  avatarHtml = `<img src='${user.avatar_url}' class='avatar avatar-inline' width='30'>`;
      const  nameHtml = `<strong class='dropdown-menu-user-full-name'>${user.name}</strong>`;
      const  usernameHtml = `<span class='dropdown-menu-user-username'>${user.username}</span>`;

      return `<li><a href='#' data-type='${user.type}'>${avatarHtml} ${nameHtml} ${usernameHtml}</a></li>`;
    }

    roleRowHtml(role) {
      return `<li><a href='#' data-type='${role.type}'>${role.text}</a></li>`;
    }

    getActiveIds() {
      console.log('getActiveIds');
    }
  }

})(window);
