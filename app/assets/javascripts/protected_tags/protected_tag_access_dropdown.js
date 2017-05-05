/* eslint-disable no-param-reassign, no-underscore-dangle, class-methods-use-this */
/* global Flash */

import { ACCESS_LEVELS, LEVEL_TYPES } from './';

export default class ProtectedTagAccessDropdown {
  constructor(options) {
    const {
      $dropdown,
      accessLevel,
      accessLevelsData,
    } = options;
    this.options = options;
    this.isAllowedToCreateDropdown = false;
    this.groups = [];
    this.accessLevel = accessLevel;
    this.accessLevelsData = accessLevelsData.roles;
    this.$dropdown = $dropdown;
    this.$wrap = this.$dropdown.closest(`.${this.accessLevel}-container`);
    this.usersPath = '/autocomplete/users.json';
    this.groupsPath = '/autocomplete/project_groups.json';
    this.defaultLabel = this.$dropdown.data('defaultLabel');

    this.setSelectedItems([]);
    this.persistPreselectedItems();

    if (ACCESS_LEVELS.CREATE === this.accessLevel) {
      this.isAllowedToCreateDropdown = true;
      this.noOneObj = this.accessLevelsData[2];
    }

    this.initDropdown();
  }

  initDropdown() {
    const { onSelect, onHide } = this.options;
    this.$dropdown.glDropdown({
      data: this.getData.bind(this),
      selectable: true,
      filterable: true,
      filterRemote: true,
      multiSelect: this.$dropdown.hasClass('js-multiselect'),
      renderRow: this.renderRow.bind(this),
      toggleLabel: this.toggleLabel.bind(this),
      hidden() {
        if (onHide) {
          onHide();
        }
      },
      clicked: (item, $el, e) => {
        e.preventDefault();

        if ($el.is('.is-active')) {
          if (this.isAllowedToCreateDropdown) {
            if (item.id === this.noOneObj.id) {
              this.accessLevelsData.forEach((level) => {
                if (level.id !== item.id) {
                  this.removeSelectedItem(level);
                }
              });

              this.$wrap.find(`.item-${item.type}`).removeClass('is-active');
            } else {
              const $noOne = this.$wrap.find(`.is-active-item-${item.type}:contains('No one')`);
              if ($noOne.length) {
                $noOne.removeClass('is-active');
                this.removeSelectedItem(this.noOneObj);
              }
            }

            $el.addClass(`is-active item-${item.type}`);
          }

          this.addSelectedItem(item);
        } else {
          this.removeSelectedItem(item);
        }

        if (onSelect) {
          onSelect(item, $el, this);
        }
      },
    });
  }

  persistPreselectedItems() {
    const itemsToPreselect = this.$dropdown.data('preselectedItems');

    if (!itemsToPreselect || !itemsToPreselect.length) {
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
    return this.items.filter(item => !item._destroy);
  }

  getAllSelectedItems() {
    return this.items;
  }

  getInputData() {
    const accessLevels = [];
    const selectedItems = this.getAllSelectedItems();

    selectedItems.forEach((item) => {
      const obj = {};

      if (typeof item.id !== 'undefined') {
        obj.id = item.id;
      }

      if (typeof item._destroy !== 'undefined') {
        obj._destroy = item._destroy;
      }

      if (item.type === LEVEL_TYPES.ROLE) {
        obj.access_level = item.access_level;
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
    let itemToAdd = {};

    // If the item already exists, just use it
    let index = -1;
    const selectedItems = this.getAllSelectedItems();

    selectedItems.forEach((item, i) => {
      if (selectedItem.id === item.access_level) {
        index = i;
      }
    });

    if (index !== -1 && selectedItems[index]._destroy) {
      delete selectedItems[index]._destroy;
      return;
    }

    itemToAdd.type = selectedItem.type;

    if (selectedItem.type === LEVEL_TYPES.USER) {
      itemToAdd = {
        user_id: selectedItem.id,
        name: selectedItem.name || '-name1',
        username: selectedItem.username || '-username1',
        avatar_url: selectedItem.avatar_url || '-avatar_url1',
        type: LEVEL_TYPES.USER,
      };
    } else if (selectedItem.type === LEVEL_TYPES.ROLE) {
      itemToAdd = {
        access_level: selectedItem.id,
        type: LEVEL_TYPES.ROLE,
      };
    } else if (selectedItem.type === LEVEL_TYPES.GROUP) {
      itemToAdd = {
        group_id: selectedItem.id,
        type: LEVEL_TYPES.GROUP,
      };
    }

    this.items.push(itemToAdd);
  }

  removeSelectedItem(itemToDelete) {
    let index = -1;
    const selectedItems = this.getAllSelectedItems();

    // To find itemToDelete on selectedItems, first we need the index
    selectedItems.every((item, i) => {
      if (item.type !== itemToDelete.type) {
        return true;
      }

      if (item.type === LEVEL_TYPES.USER &&
        item.user_id === itemToDelete.id) {
        index = i;
      } else if (item.type === LEVEL_TYPES.ROLE &&
        item.access_level === itemToDelete.id) {
        index = i;
      } else if (item.type === LEVEL_TYPES.GROUP &&
        item.group_id === itemToDelete.id) {
        index = i;
      }

      return index < 0; // Break once we have index set
    });

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

  toggleLabel() {
    const currentItems = this.getSelectedItems();
    const types = _.groupBy(currentItems, item => item.type);
    const label = [];

    if (currentItems.length) {
      Object.keys(LEVEL_TYPES).forEach((levelType) => {
        const typeName = LEVEL_TYPES[levelType];
        const numberOfTypes = types[typeName] ? types[typeName].length : 0;
        const text = numberOfTypes === 1 ? typeName : `${typeName}s`;

        label.push(`${numberOfTypes} ${text}`);
      });
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
        }).error(() => new Flash('Failed to load groups.'));
      }
    }).error(() => new Flash('Failed to load users.'));
  }

  consolidateData(usersResponse, groupsResponse) {
    let consolidatedData = [];
    const map = [];
    const users = [];
    const selectedItems = this.getSelectedItems();

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
    const groups = groupsResponse.map((group) => {
      group.type = LEVEL_TYPES.GROUP;
      return group;
    });

    /*
     * Build roles
     */
    const roles = this.accessLevelsData.map((level) => {
      level.type = LEVEL_TYPES.ROLE;
      return level;
    });

    /*
     * Build users
     */
    selectedItems.forEach((item) => {
      if (item.type !== LEVEL_TYPES.USER) {
        return;
      }

      // Collect selected users
      users.push({
        id: item.user_id,
        name: item.name,
        username: item.username,
        avatar_url: item.avatar_url,
        type: LEVEL_TYPES.USER,
      });

      // Save identifiers for easy-checking more later
      map.push(LEVEL_TYPES.USER + item.user_id);
    });

    // Has to be checked against server response
    // because the selected item can be in filter results
    usersResponse.forEach((response) => {
      // Add is it has not been added
      if (map.indexOf(LEVEL_TYPES.USER + response.id) === -1) {
        response.type = LEVEL_TYPES.USER;
        users.push(response);
      }
    });

    if (roles.length) {
      consolidatedData = consolidatedData.concat([{ header: 'Roles' }], roles);
    }

    if (groups.length) {
      if (roles.length) {
        consolidatedData = consolidatedData.concat(['divider']);
      }

      consolidatedData = consolidatedData.concat([{ header: 'Groups' }], groups);
    }

    if (users.length) {
      consolidatedData = consolidatedData.concat(['divider'], [{ header: 'Users' }], users);
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
      },
    });
  }

  getGroups() {
    return $.ajax({
      dataType: 'json',
      url: this.buildUrl(this.groupsPath),
      data: {
        project_id: gon.current_project_id,
      },
    });
  }

  buildUrl(url) {
    if (gon.relative_url_root !== null) {
      url = gon.relative_url_root.replace(/\/$/, '') + url;
    }
    return url;
  }

  renderRow(item) {
    let criteria = {};
    let groupRowEl;

    // Detect if the current item is already saved so we can add
    // the `is-active` class so the item looks as marked
    switch (item.type) {
      case LEVEL_TYPES.USER:
        criteria = { user_id: item.id };
        break;
      case LEVEL_TYPES.ROLE:
        criteria = { access_level: item.id };
        break;
      case LEVEL_TYPES.GROUP:
        criteria = { group_id: item.id };
        break;
      default:
        break;
    }

    const isActive = _.findWhere(this.getSelectedItems(), criteria) ? 'is-active' : '';

    switch (item.type) {
      case LEVEL_TYPES.USER:
        groupRowEl = this.userRowHtml(item, isActive);
        break;
      case LEVEL_TYPES.ROLE:
        groupRowEl = this.roleRowHtml(item, isActive);
        break;
      case LEVEL_TYPES.GROUP:
        groupRowEl = this.groupRowHtml(item, isActive);
        break;
      default:
        groupRowEl = '';
        break;
    }

    return groupRowEl;
  }

  userRowHtml(user, isActive) {
    const avatarHtml = `<img src='${user.avatar_url}' class='avatar avatar-inline' width='30'>`;
    const nameHtml = `<strong class='dropdown-menu-user-full-name'>${user.name}</strong>`;
    const usernameHtml = `<span class='dropdown-menu-user-username'>${user.username}</span>`;
    return `<li><a href='#' class='${isActive ? 'is-active' : ''}'>${avatarHtml} ${nameHtml} ${usernameHtml}</a></li>`;
  }

  groupRowHtml(group, isActive) {
    const avatarHtml = group.avatar_url ? `<img src='${group.avatar_url}' class='avatar avatar-inline' width='30'>` : '';
    const groupnameHtml = `<span class='dropdown-menu-group-groupname'>${group.name}</span>`;
    return `<li><a href='#' class='${isActive ? 'is-active' : ''}'>${avatarHtml} ${groupnameHtml}</a></li>`;
  }

  roleRowHtml(role, isActive) {
    return `<li><a href='#' class='${isActive ? 'is-active' : ''} item-${role.type}'>${role.text}</a></li>`;
  }
}
