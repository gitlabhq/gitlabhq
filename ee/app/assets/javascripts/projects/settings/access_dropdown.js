/* eslint-disable no-underscore-dangle, class-methods-use-this */

import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import Flash from '~/flash';
import { n__ } from '~/locale';
import { LEVEL_TYPES, LEVEL_ID_PROP, ACCESS_LEVEL_NONE } from './constants';

export default class AccessDropdown {
  constructor(options) {
    const { $dropdown, accessLevel, accessLevelsData } = options;
    this.options = options;
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

    this.noOneObj = this.accessLevelsData.find(level => level.id === ACCESS_LEVEL_NONE);

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
      clicked: options => {
        const { $el, e } = options;
        const item = options.selectedObj;

        e.preventDefault();

        if ($el.is('.is-active')) {
          if (item.id === this.noOneObj.id) {
            // remove all others selected items
            this.accessLevelsData.forEach(level => {
              if (level.id !== item.id) {
                this.removeSelectedItem(level);
              }
            });

            // remove selected item visually
            this.$wrap.find(`.item-${item.type}`).removeClass('is-active');
          } else {
            const $noOne = this.$wrap.find(
              `.is-active.item-${item.type}[data-role-id="${this.noOneObj.id}"]`,
            );
            if ($noOne.length) {
              $noOne.removeClass('is-active');
              this.removeSelectedItem(this.noOneObj);
            }
          }

          // make element active right away
          $el.addClass(`is-active item-${item.type}`);

          // Add "No one"
          this.addSelectedItem(item);
        } else {
          this.removeSelectedItem(item);
        }

        if (onSelect) {
          onSelect(item, $el, this);
        }
      },
    });

    this.$dropdown.find('.dropdown-toggle-text').text(this.toggleLabel());
  }

  persistPreselectedItems() {
    const itemsToPreselect = this.$dropdown.data('preselectedItems');

    if (!itemsToPreselect || !itemsToPreselect.length) {
      return;
    }

    const persistedItems = itemsToPreselect.map(item => {
      const persistedItem = Object.assign({}, item);
      persistedItem.persisted = true;
      return persistedItem;
    });

    this.setSelectedItems(persistedItems);
  }

  setSelectedItems(items = []) {
    this.items = items;
  }

  getSelectedItems() {
    return this.items.filter(item => !item._destroy);
  }

  getAllSelectedItems() {
    return this.items;
  }

  // Return dropdown as input data ready to submit
  getInputData() {
    const selectedItems = this.getAllSelectedItems();

    const accessLevels = selectedItems.map(item => {
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

      return obj;
    });

    return accessLevels;
  }

  addSelectedItem(selectedItem) {
    let itemToAdd = {};

    let index = -1;
    let alreadyAdded = false;
    const selectedItems = this.getAllSelectedItems();

    // Compare IDs based on selectedItem.type
    selectedItems.forEach((item, i) => {
      let comparator;
      switch (selectedItem.type) {
        case LEVEL_TYPES.ROLE:
          comparator = LEVEL_ID_PROP.ROLE;
          // If the item already exists, just use it
          if (item[comparator] === selectedItem.id) {
            alreadyAdded = true;
          }
          break;
        case LEVEL_TYPES.GROUP:
          comparator = LEVEL_ID_PROP.GROUP;
          break;
        case LEVEL_TYPES.USER:
          comparator = LEVEL_ID_PROP.USER;
          break;
        default:
          break;
      }

      if (selectedItem.id === item[comparator]) {
        index = i;
      }
    });

    if (alreadyAdded) {
      return;
    }

    if (index !== -1 && selectedItems[index]._destroy) {
      delete selectedItems[index]._destroy;
      return;
    }

    itemToAdd.type = selectedItem.type;

    if (selectedItem.type === LEVEL_TYPES.USER) {
      itemToAdd = {
        user_id: selectedItem.id,
        name: selectedItem.name || '_name1',
        username: selectedItem.username || '_username1',
        avatar_url: selectedItem.avatar_url || '_avatar_url1',
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

      if (item.type === LEVEL_TYPES.USER && item.user_id === itemToDelete.id) {
        index = i;
      } else if (item.type === LEVEL_TYPES.ROLE && item.access_level === itemToDelete.id) {
        index = i;
      } else if (item.type === LEVEL_TYPES.GROUP && item.group_id === itemToDelete.id) {
        index = i;
      }

      // Break once we have index set
      return !(index > -1);
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
    const $dropdownToggleText = this.$dropdown.find('.dropdown-toggle-text');

    if (currentItems.length === 0) {
      $dropdownToggleText.addClass('is-default');
      return this.defaultLabel;
    }

    $dropdownToggleText.removeClass('is-default');

    if (currentItems.length === 1 && currentItems[0].type === LEVEL_TYPES.ROLE) {
      const roleData = this.accessLevelsData.find(data => data.id === currentItems[0].access_level);
      return roleData.text;
    }

    const labelPieces = [];
    const counts = _.countBy(currentItems, item => item.type);

    if (counts[LEVEL_TYPES.ROLE] > 0) {
      labelPieces.push(n__('1 role', '%d roles', counts[LEVEL_TYPES.ROLE]));
    }

    if (counts[LEVEL_TYPES.USER] > 0) {
      labelPieces.push(n__('1 user', '%d users', counts[LEVEL_TYPES.USER]));
    }

    if (counts[LEVEL_TYPES.GROUP] > 0) {
      labelPieces.push(n__('1 group', '%d groups', counts[LEVEL_TYPES.GROUP]));
    }

    return labelPieces.join(', ');
  }

  getData(query, callback) {
    Promise.all([
      this.getUsers(query),
      this.groupsData ? Promise.resolve(this.groupsData) : this.getGroups(),
    ])
      .then(([usersResponse, groupsResponse]) => {
        this.groupsData = groupsResponse;
        callback(this.consolidateData(usersResponse.data, groupsResponse.data));
      })
      .catch(() => Flash('Failed to load groups & users.'));
  }

  consolidateData(usersResponse, groupsResponse) {
    let consolidatedData = [];
    const map = [];
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
    const groups = groupsResponse.map(group => ({
      ...group,
      type: LEVEL_TYPES.GROUP,
    }));

    /*
     * Build roles
     */
    const roles = this.accessLevelsData.map(level => {
      /* eslint-disable no-param-reassign */
      // This re-assignment is intentional as
      // level.type property is being used in removeSelectedItem()
      // for comparision, and accessLevelsData is provided by
      // gon.create_access_levels which doesn't have `type` included.
      // See this discussion https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1629#note_31285823
      level.type = LEVEL_TYPES.ROLE;
      return level;
    });

    /*
     * Build users
     */
    const users = selectedItems.filter(item => item.type === LEVEL_TYPES.USER).map(item => {
      // Save identifiers for easy-checking more later
      map.push(LEVEL_TYPES.USER + item.user_id);

      return {
        id: item.user_id,
        name: item.name,
        username: item.username,
        avatar_url: item.avatar_url,
        type: LEVEL_TYPES.USER,
      };
    });

    // Has to be checked against server response
    // because the selected item can be in filter results
    usersResponse.forEach(response => {
      // Add is it has not been added
      if (map.indexOf(LEVEL_TYPES.USER + response.id) === -1) {
        const user = Object.assign({}, response);
        user.type = LEVEL_TYPES.USER;
        users.push(user);
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
    return axios.get(this.buildUrl(gon.relative_url_root, this.usersPath), {
      params: {
        search: query,
        per_page: 20,
        active: true,
        project_id: gon.current_project_id,
        push_code: true,
      },
    });
  }

  getGroups() {
    return axios.get(this.buildUrl(gon.relative_url_root, this.groupsPath), {
      params: {
        project_id: gon.current_project_id,
      },
    });
  }

  buildUrl(urlRoot, url) {
    let newUrl;
    if (urlRoot != null) {
      newUrl = urlRoot.replace(/\/$/, '') + url;
    }
    return newUrl;
  }

  renderRow(item) {
    let criteria = {};
    let groupRowEl;

    // Dectect if the current item is already saved so we can add
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
    const isActiveClass = isActive || '';

    return `
      <li>
        <a href="#" class="${isActiveClass}">
          <img src="${user.avatar_url}" class="avatar avatar-inline" width="30">
          <strong class="dropdown-menu-user-full-name">${user.name}</strong>
          <span class="dropdown-menu-user-username">${user.username}</span>
        </a>
      </li>
    `;
  }

  groupRowHtml(group, isActive) {
    const isActiveClass = isActive || '';
    const avatarEl = group.avatar_url
      ? `<img src="${group.avatar_url}" class="avatar avatar-inline" width="30">`
      : '';

    return `
      <li>
        <a href="#" class="${isActiveClass}">
          ${avatarEl}
          <span class="dropdown-menu-group-groupname">${group.name}</span>
        </a>
      </li>
    `;
  }

  roleRowHtml(role, isActive) {
    const isActiveClass = isActive || '';

    return `
      <li>
        <a href="#" class="${isActiveClass} item-${role.type}" data-role-id="${role.id}">
          ${role.text}
        </a>
      </li>
    `;
  }
}
