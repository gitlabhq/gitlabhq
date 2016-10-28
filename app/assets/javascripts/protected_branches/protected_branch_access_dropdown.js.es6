/* eslint-disable */
(global => {
  global.gl = global.gl || {};

  const PUSH_ACCESS_LEVEL = 'push_access_levels';
  const LEVEL_TYPES = {
    ROLE: 'role',
    USER: 'user',
    GROUP: 'group'
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

      this.isAllowedToPushDropdown = false;
      this.groups = [];
      this.accessLevel = accessLevel;
      this.accessLevelsData = accessLevelsData;
      this.$dropdown = $dropdown;
      this.$wrap = this.$dropdown.closest(`.${this.accessLevel}-container`);
      this.usersPath = '/autocomplete/users.json';
      this.groupsPath = '/autocomplete/project_groups.json';
      this.defaultLabel = this.$dropdown.data('defaultLabel');

      this.setSelectedItems([]);
      this.persistPreselectedItems();

      if (PUSH_ACCESS_LEVEL === this.accessLevel) {
        this.isAllowedToPushDropdown = true;
        this.noOneObj = this.accessLevelsData[2];
      }

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
            if (self.isAllowedToPushDropdown) {
              if (item.id === self.noOneObj.id) {

                // remove all others selected items
                self.accessLevelsData.forEach((level) => {
                  if (level.id !== item.id) {
                    self.removeSelectedItem(level);
                  }
                });

                // remove selected item visually
                self.$wrap.find(`.item-${item.type}`).removeClass(`is-active`);
              } else {
                let $noOne = self.$wrap.find(`.is-active.item-${item.type}:contains('No one')`);
                if ($noOne.length) {
                  $noOne.removeClass('is-active');
                  self.removeSelectedItem(self.noOneObj);
                }
              }

              // make element active right away
              $el.addClass(`is-active item-${item.type}`);
            }

            // Add "No one"
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
        } else if (item.type === LEVEL_TYPES.GROUP) {
          obj.group_id = item.group_id;
        }

        accessLevels.push(obj);
      });

      return accessLevels;
    }

    addSelectedItem(selectedItem) {
      var itemToAdd = {};

      // If the item already exists, just use it 
      let index = -1;
      let selectedItems = this.getAllSelectedItems();

      for (var i = 0; i < selectedItems.length; i++) {
        if (selectedItem.id === selectedItems[i].access_level) {
          index = i;
          continue;
        }
      }

      if (index !== -1 && selectedItems[index]._destroy) {
        delete selectedItems[index]._destroy;
        return;
      }

      itemToAdd.type = selectedItem.type;

      if (selectedItem.type === LEVEL_TYPES.USER) {
        itemToAdd = {
          user_id: selectedItem.id,
          name: selectedItem.name || '_name1',
          username: selectedItem.username || '_username1',
          avatar_url: selectedItem.avatar_url || '_avatar_url1',
          type: LEVEL_TYPES.USER
        };
      } else if (selectedItem.type === LEVEL_TYPES.ROLE) {
        itemToAdd = {
          access_level: selectedItem.id,
          type: LEVEL_TYPES.ROLE
        }
      } else if (selectedItem.type === LEVEL_TYPES.GROUP) {
        itemToAdd = {
          group_id: selectedItem.id,
          type: LEVEL_TYPES.GROUP
        }
      }

      this.items.push(itemToAdd);
    }

    removeSelectedItem(itemToDelete) {
      let index = -1;
      let selectedItems = this.getAllSelectedItems();

      // To find itemToDelete on selectedItems, first we need the index
      for (let i = 0; i < selectedItems.length; i++) {
        let currentItem = selectedItems[i];

        if (currentItem.type !== itemToDelete.type) {
          continue;
        }

        if (currentItem.type === LEVEL_TYPES.USER && currentItem.user_id === itemToDelete.id) {
          index = i;
        } else if (currentItem.type === LEVEL_TYPES.ROLE && currentItem.access_level === itemToDelete.id) {
          index = i;
        } else if (currentItem.type === LEVEL_TYPES.GROUP && currentItem.group_id === itemToDelete.id) {
          index = i;
        }

        if (index > -1) { break; }
      }

      // if ItemToDelete is not really selected do nothing
      if (index === -1) {
        return;
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

      this.$dropdown.find('.dropdown-toggle-text').toggleClass('is-default', !currentItems.length);

      return label.join(', ');
    }

    getData(query, callback) {
      this.getUsers(query).done((usersResponse) => {
        if (this.groups.length) {
          callback(this.consolidateData(usersResponse, this.groups));
        } else {
         this.getGroups(query).done((groupsResponse) => {

            // Cache groups to avoid multiple requests
            this.groups = groupsResponse;
            callback(this.consolidateData(usersResponse, groupsResponse));
         });
        }

      }).error(() => {
        new Flash('Failed to load users.');
      });
    }

    consolidateData(usersResponse, groupsResponse) {
      let consolidatedData = [];
      let map = [];
      let roles = [];
      let selectedUsers = [];
      let unselectedUsers = [];
      let groups = [];
      let selectedItems = this.getSelectedItems();

      // ID property is handled differently locally from the server
      // 
      // For Groups
      // In dropdown: `id` 
      // For submit: `group_id`
      // 
      // For Roles
      // In dropdown: `id` 
      // For submit: `access_level`
      // 
      // For Users
      // In dropdown: `id` 
      // For submit: `user_id`

      /*
       * Build groups
       */
      groups = groupsResponse.map((group) => {
        group.type = LEVEL_TYPES.GROUP;
        return group;
      });

      /*
       * Build roles
       */
      roles = this.accessLevelsData.map((level) => {
        level.type = LEVEL_TYPES.ROLE;
        return level;
      });

      /*
       * Build users
       */
      for (let x = 0; x < selectedItems.length; x++) {
        let current = selectedItems[x];

        if (current.type !== LEVEL_TYPES.USER) { continue; }

        // Collect selected users 
        selectedUsers.push({
          id: current.user_id,
          name: current.name,
          username: current.username,
          avatar_url: current.avatar_url,
          type: LEVEL_TYPES.USER
        });

        // Save identifiers for easy-checking more later
        map.push(LEVEL_TYPES.USER + current.user_id);
      }

      // Has to be checked against server response
      // because the selected item can be in filter results
      for (let i = 0; i < usersResponse.length; i++) {
        let u = usersResponse[i];

        // Add is it has not been added
        if (map.indexOf(LEVEL_TYPES.USER + u.id) === -1){
          u.type = LEVEL_TYPES.USER;
          unselectedUsers.push(u);
        }
      }

      if (groups.length) {
        consolidatedData =consolidatedData.concat(groups);
      }

      if (roles.length) {
        if (groups.length) {
          consolidatedData = consolidatedData.concat(['divider']);
        }

        consolidatedData = consolidatedData.concat(roles);
      }

      if (selectedUsers.length) {
        consolidatedData = consolidatedData.concat(['divider'], selectedUsers);
      }

      if (unselectedUsers.length) {
        if (!selectedUsers.length) {
          consolidatedData = consolidatedData.concat(['divider']);
        }

        consolidatedData = consolidatedData.concat(unselectedUsers);
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

    getGroups(query) {
     return $.ajax({
       dataType: 'json',
       url: this.buildUrl(this.groupsPath),
       data: {
         project_id: gon.current_project_id
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
      if (item.type === LEVEL_TYPES.USER) {
        criteria = { user_id: item.id };
      } else if (item.type === LEVEL_TYPES.ROLE) {
        criteria = { access_level: item.id };
      } else if (item.type === LEVEL_TYPES.GROUP) {
        criteria = { group_id: item.id };
      }

      isActive = _.findWhere(this.getSelectedItems(), criteria) ? 'is-active' : '';

      if (item.type === LEVEL_TYPES.USER) {
        return this.userRowHtml(item, isActive);
      } else if (item.type === LEVEL_TYPES.ROLE) {
        return this.roleRowHtml(item, isActive);
      } else if (item.type === LEVEL_TYPES.GROUP) {
        return this.groupRowHtml(item, isActive);
      }
    }

    userRowHtml(user, isActive) {
      const  avatarHtml = `<img src='${user.avatar_url}' class='avatar avatar-inline' width='30'>`;
      const  nameHtml = `<strong class='dropdown-menu-user-full-name'>${user.name}</strong>`;
      const  usernameHtml = `<span class='dropdown-menu-user-username'>${user.username}</span>`;
      return `<li><a href='#' class='${isActive ? 'is-active' : ''}'>${avatarHtml} ${nameHtml} ${usernameHtml}</a></li>`;
    }

    groupRowHtml(group, isActive) {
     const  avatarHtml = group.avatar_url ? `<img src='${group.avatar_url}' class='avatar avatar-inline' width='30'>` : '';
     const  nameHtml = `<strong class='dropdown-menu-group-full-name'>${group.name}</strong>`;
     const  groupnameHtml = `<span class='dropdown-menu-group-groupname'>${group.name}</span>`;
     return `<li><a href='#' class='${isActive ? 'is-active' : ''}'>${avatarHtml} ${nameHtml} ${groupnameHtml}</a></li>`;
    }

    roleRowHtml(role, isActive) {
      return `<li><a href='#' class='${isActive ? 'is-active' : ''} item-${role.type}'>${role.text}</a></li>`;
    }
  }

})(window);
