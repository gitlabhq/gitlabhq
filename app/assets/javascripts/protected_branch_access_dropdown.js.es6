(global => {
  global.gl = global.gl || {};

  const LEVEL_TYPES = {
    ROLE: 'role',
    USER: 'user'
  };

  gl.ProtectedBranchAccessDropdown = class {
    constructor(options) {
      const self = this;
      const {
        $dropdown,
        onSelect,
        onHide,
        accessLevel,
        accessLevelsData
      } = options;

      this.accessLevel = accessLevel;
      this.accessLevelsData = accessLevelsData;
      this.$dropdown = $dropdown;
      this.$wrap = this.$dropdown.closest(`.${this.accessLevel}-container`);
      this.usersPath = '/autocomplete/users.json';
      this.defaultLabel = this.$dropdown.data('defaultLabel');

      this.setSelectedItems([]);
      this.persistPreselectedItems();

      $dropdown.glDropdown({
        selectable: true,
        filterable: true,
        filterRemote: true,
        data: this.getData.bind(this),
        multiSelect: $dropdown.hasClass('js-multiselect'),
        renderRow: this.renderRow.bind(this),
        toggleLabel: this.toggleLabel.bind(this),
        hidden() {
          if (onHide) {
            onHide();
          }
        },
        clicked(item, $el, e) {
          e.preventDefault();

          if ($el.is('.is-active')) {
            self.addSelectedItem(item);
          } else {
            self.removeSelectedItem(item);
          }

          if (onSelect) {
            onSelect(item, $el, self);
          }
        }
      });
    }

    persistPreselectedItems() {
      let itemsToPreselect = this.$dropdown.data('preselectedItems');

      if (typeof itemsToPreselect === 'undefined' || !itemsToPreselect.length) {
        return;
      }

      itemsToPreselect.forEach((item) => {
        item.persisted = true;
      });

      this.setSelectedItems(itemsToPreselect);
    }

    setSelectedItems(items) {
      this.items = items.length ? items : [];
    }

    getSelectedItems() {
      return this.items.filter((item) => {
        return !item._destroy;
      });
    }

    getAllSelectedItems() {
      return this.items;
    }

    // Return dropdown as input data ready to submit
    getInputData() {
      let accessLevels = [];
      let selectedItems = this.getAllSelectedItems();

      selectedItems.map((item) => {
        let obj = {};

        if (typeof item.id !== 'undefined') {
          obj.id = item.id;
        }

        if (typeof item._destroy !== 'undefined') {
          obj._destroy = item._destroy;
        }

        if (item.type === LEVEL_TYPES.ROLE) {
          obj.access_level = item.access_level
        } else if (item.type === LEVEL_TYPES.USER) {
          obj.user_id = item.user_id;
        }

        accessLevels.push(obj);
      });

      return accessLevels;
    }

    addSelectedItem(selectedItem) {
      var itemToAdd = {};

      itemToAdd.type = selectedItem.type;

      if (selectedItem.type === 'user') {
        itemToAdd = {
          user_id: selectedItem.id,
          name: selectedItem.name || '_name1',
          username: selectedItem.username || '_username1',
          avatar_url: selectedItem.avatar_url || '_avatar_url1',
          type: 'user'
        };
      } else if (selectedItem.type === 'role') {
        itemToAdd = {
          access_level: selectedItem.id,
          type: 'role'
        }
      }
      this.items.push(itemToAdd);
    }

    removeSelectedItem(itemToDelete) {
      let index;
      let selectedItems = this.getAllSelectedItems();

      // To find itemToDelete on selectedItems, first we need the index
      for (let i = 0; i < selectedItems.length; i++) {
        let currentItem = selectedItems[i];

        if (currentItem.type === 'user' &&
          (currentItem.user_id === itemToDelete.id && currentItem.type === itemToDelete.type)) {
          index = i;
        } else if (currentItem.type === 'role' &&
          (currentItem.access_level === itemToDelete.id && currentItem.type === itemToDelete.type)) {
          index = i;
        }

        if (index) { break; }
      }

      if (selectedItems[index].persisted) {
        // If we toggle an item that has been already marked with _destroy
        if (selectedItems[index]._destroy) {
          delete selectedItems[index]._destroy;
        } else {
          selectedItems[index]._destroy = '1';
        }
      } else {
        selectedItems.splice(index, 1);
      }
    }

    toggleLabel(selectedItem, el) {
      let currentItems = this.getSelectedItems();
      let types = _.groupBy(currentItems, (item) => { return item.type; });
      let label = [];

      if (currentItems.length) {
        for (let LEVEL_TYPE in LEVEL_TYPES) {
          let typeName = LEVEL_TYPES[LEVEL_TYPE];
          let numberOfTypes = types[typeName] ? types[typeName].length : 0;
          let text = numberOfTypes === 1 ? typeName : `${typeName}s`;

          label.push(`${numberOfTypes} ${text}`);
        }
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
      let users;
      let mergeAccessLevels;
      let consolidatedData;
      let selectedItems = this.getSelectedItems();

      mergeAccessLevels = this.accessLevelsData.map((level) => {
        level.type = 'role';
        return level;
      });

      let aggregate = [];
      let map = [];

      for (let x = 0; x < selectedItems.length; x++) {
        let current = selectedItems[x];

        if (current.type !== 'user') { continue; }

        map.push(current.user_id);

        aggregate.push({
          id: current.user_id,
          name: current.name,
          username: current.username,
          avatar_url: current.avatar_url,
          type: 'user'
        });
      }

      for (let i = 0; i < response.length; i++) {
        let x = response[i];

        // Add is it has not been added
        if (map.indexOf(x.id) === -1){
          x.type = 'user';
          aggregate.push(x);
        }
      }

      consolidatedData = mergeAccessLevels;

      if (aggregate.length) {
        consolidatedData = mergeAccessLevels.concat(['divider'], aggregate);
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
      let isActive;
      let criteria = {};

      // Dectect if the current item is already saved so we can add
      // the `is-active` class so the item looks as marked
      if (item.type === 'user') {
        criteria = { user_id: item.id };
      } else if (item.type === 'role') {
        criteria = { access_level: item.id };
      }

      isActive = _.findWhere(this.getSelectedItems(), criteria) ? 'is-active' : '';

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
      return `<li><a href='#' class='${isActive ? 'is-active' : ''}'>${avatarHtml} ${nameHtml} ${usernameHtml}</a></li>`;
    }

    roleRowHtml(role, isActive) {
      return `<li><a href='#' class='${isActive ? 'is-active' : ''}'>${role.text}</a></li>`;
    }
  }

})(window);
