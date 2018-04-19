/* eslint-disable func-names, space-before-function-paren, one-var, no-var, prefer-rest-params, wrap-iife, quotes, max-len, one-var-declaration-per-line, vars-on-top, prefer-arrow-callback, consistent-return, comma-dangle, object-shorthand, no-shadow, no-unused-vars, no-else-return, no-self-compare, prefer-template, no-unused-expressions, no-lonely-if, yoda, prefer-spread, no-void, camelcase, no-param-reassign */
/* global Issuable */
/* global emitSidebarEvent */

import $ from 'jquery';
import _ from 'underscore';
import axios from './lib/utils/axios_utils';
import ModalStore from './boards/stores/modal_store';

// TODO: remove eventHub hack after code splitting refactor
window.emitSidebarEvent = window.emitSidebarEvent || $.noop;

function UsersSelect(currentUser, els, options = {}) {
  var $els;
  this.users = this.users.bind(this);
  this.user = this.user.bind(this);
  this.usersPath = "/autocomplete/users.json";
  this.userPath = "/autocomplete/users/:id.json";
  if (currentUser != null) {
    if (typeof currentUser === 'object') {
      this.currentUser = currentUser;
    } else {
      this.currentUser = JSON.parse(currentUser);
    }
  }

  const { handleClick } = options;

  $els = $(els);

  if (!els) {
    $els = $('.js-user-search');
  }

  $els.each((function(_this) {
    return function(i, dropdown) {
      var options = {};
      var $block, $collapsedSidebar, $dropdown, $loading, $selectbox, $value, abilityName, assignTo, assigneeTemplate, collapsedAssigneeTemplate, defaultLabel, defaultNullUser, firstUser, issueURL, selectedId, selectedIdDefault, showAnyUser, showNullUser, showMenuAbove;
      $dropdown = $(dropdown);
      options.projectId = $dropdown.data('projectId');
      options.groupId = $dropdown.data('groupId');
      options.showCurrentUser = $dropdown.data('currentUser');
      options.todoFilter = $dropdown.data('todoFilter');
      options.todoStateFilter = $dropdown.data('todoStateFilter');
      showNullUser = $dropdown.data('nullUser');
      defaultNullUser = $dropdown.data('nullUserDefault');
      showMenuAbove = $dropdown.data('showMenuAbove');
      showAnyUser = $dropdown.data('anyUser');
      firstUser = $dropdown.data('firstUser');
      options.authorId = $dropdown.data('authorId');
      defaultLabel = $dropdown.data('defaultLabel');
      issueURL = $dropdown.data('issueUpdate');
      $selectbox = $dropdown.closest('.selectbox');
      $block = $selectbox.closest('.block');
      abilityName = $dropdown.data('abilityName');
      $value = $block.find('.value');
      $collapsedSidebar = $block.find('.sidebar-collapsed-user');
      $loading = $block.find('.block-loading').fadeOut();
      selectedIdDefault = (defaultNullUser && showNullUser) ? 0 : null;
      selectedId = $dropdown.data('selected');

      if (selectedId === undefined) {
        selectedId = selectedIdDefault;
      }

      const assignYourself = function () {
        const unassignedSelected = $dropdown.closest('.selectbox')
          .find(`input[name='${$dropdown.data('fieldName')}'][value=0]`);

        if (unassignedSelected) {
          unassignedSelected.remove();
        }

        // Save current selected user to the DOM
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = $dropdown.data('fieldName');

        const currentUserInfo = $dropdown.data('currentUserInfo');

        if (currentUserInfo) {
          input.value = currentUserInfo.id;
          input.dataset.meta = _.escape(currentUserInfo.name);
        } else if (_this.currentUser) {
          input.value = _this.currentUser.id;
        }

        if ($selectbox) {
          $dropdown.parent().before(input);
        } else {
          $dropdown.after(input);
        }
      };

      if ($block[0]) {
        $block[0].addEventListener('assignYourself', assignYourself);
      }

      const getSelectedUserInputs = function() {
        return $selectbox
          .find(`input[name="${$dropdown.data('fieldName')}"]`);
      };

      const getSelected = function() {
        return getSelectedUserInputs()
          .map((index, input) => parseInt(input.value, 10))
          .get();
      };

      const checkMaxSelect = function() {
        const maxSelect = $dropdown.data('maxSelect');
        if (maxSelect) {
          const selected = getSelected();

          if (selected.length > maxSelect) {
            const firstSelectedId = selected[0];
            const firstSelected = $dropdown.closest('.selectbox')
              .find(`input[name='${$dropdown.data('fieldName')}'][value=${firstSelectedId}]`);

            firstSelected.remove();
            emitSidebarEvent('sidebar.removeAssignee', {
              id: firstSelectedId,
            });
          }
        }
      };

      const getMultiSelectDropdownTitle = function(selectedUser, isSelected) {
        const selectedUsers = getSelected()
          .filter(u => u !== 0);

        const firstUser = getSelectedUserInputs()
          .map((index, input) => ({
            name: input.dataset.meta,
            value: parseInt(input.value, 10),
          }))
          .filter(u => u.id !== 0)
          .get(0);

        if (selectedUsers.length === 0) {
          return 'Unassigned';
        } else if (selectedUsers.length === 1) {
          return firstUser.name;
        } else if (isSelected) {
          const otherSelected = selectedUsers.filter(s => s !== selectedUser.id);
          return `${selectedUser.name} + ${otherSelected.length} more`;
        } else {
          return `${firstUser.name} + ${selectedUsers.length - 1} more`;
        }
      };

      $('.assign-to-me-link').on('click', (e) => {
        e.preventDefault();
        $(e.currentTarget).hide();

        if ($dropdown.data('multiSelect')) {
          assignYourself();
          checkMaxSelect();

          const currentUserInfo = $dropdown.data('currentUserInfo');
          $dropdown.find('.dropdown-toggle-text').text(getMultiSelectDropdownTitle(currentUserInfo)).removeClass('is-default');
        } else {
          const $input = $(`input[name="${$dropdown.data('fieldName')}"]`);
          $input.val(gon.current_user_id);
          selectedId = $input.val();
          $dropdown.find('.dropdown-toggle-text').text(gon.current_user_fullname).removeClass('is-default');
        }
      });

      $block.on('click', '.js-assign-yourself', (e) => {
        e.preventDefault();
        return assignTo(_this.currentUser.id);
      });

      assignTo = function(selected) {
        var data;
        data = {};
        data[abilityName] = {};
        data[abilityName].assignee_id = selected != null ? selected : null;
        $loading.removeClass('hidden').fadeIn();
        $dropdown.trigger('loading.gl.dropdown');

        return axios.put(issueURL, data)
          .then(({ data }) => {
            var user;
            $dropdown.trigger('loaded.gl.dropdown');
            $loading.fadeOut();
            if (data.assignee) {
              user = {
                name: data.assignee.name,
                username: data.assignee.username,
                avatar: data.assignee.avatar_url
              };
            } else {
              user = {
                name: 'Unassigned',
                username: '',
                avatar: ''
              };
            }
            $value.html(assigneeTemplate(user));
            $collapsedSidebar.attr('title', _.escape(user.name)).tooltip('_fixTitle');
            return $collapsedSidebar.html(collapsedAssigneeTemplate(user));
          });
      };
      collapsedAssigneeTemplate = _.template('<% if( avatar ) { %> <a class="author_link" href="/<%- username %>"> <img width="24" class="avatar avatar-inline s24" alt="" src="<%- avatar %>"> </a> <% } else { %> <i class="fa fa-user"></i> <% } %>');
      assigneeTemplate = _.template('<% if (username) { %> <a class="author_link bold" href="/<%- username %>"> <% if( avatar ) { %> <img width="32" class="avatar avatar-inline s32" alt="" src="<%- avatar %>"> <% } %> <span class="author"><%- name %></span> <span class="username"> @<%- username %> </span> </a> <% } else { %> <span class="no-value assign-yourself"> No assignee - <a href="#" class="js-assign-yourself"> assign yourself </a> </span> <% } %>');
      return $dropdown.glDropdown({
        showMenuAbove: showMenuAbove,
        data: function(term, callback) {
          return _this.users(term, options, function(users) {
            // GitLabDropdownFilter returns this.instance
            // GitLabDropdownRemote returns this.options.instance
            const glDropdown = this.instance || this.options.instance;
            glDropdown.options.processData(term, users, callback);
          }.bind(this));
        },
        processData: function(term, data, callback) {
          let users = data;

          // Only show assigned user list when there is no search term
          if ($dropdown.hasClass('js-multiselect') && term.length === 0) {
            const selectedInputs = getSelectedUserInputs();

            // Potential duplicate entries when dealing with issue board
            // because issue board is also managed by vue
            const selectedUsers = _.uniq(selectedInputs, false, a => a.value)
              .filter((input) => {
                const userId = parseInt(input.value, 10);
                const inUsersArray = users.find(u => u.id === userId);

                return !inUsersArray && userId !== 0;
              })
              .map((input) => {
                const userId = parseInt(input.value, 10);
                const { avatarUrl, avatar_url, name, username } = input.dataset;
                return {
                  avatar_url: avatarUrl || avatar_url,
                  id: userId,
                  name,
                  username,
                };
              });

            users = data.concat(selectedUsers);
          }

          let anyUser;
          let index;
          let j;
          let len;
          let name;
          let obj;
          let showDivider;
          if (term.length === 0) {
            showDivider = 0;
            if (firstUser) {
              // Move current user to the front of the list
              for (index = j = 0, len = users.length; j < len; index = (j += 1)) {
                obj = users[index];
                if (obj.username === firstUser) {
                  users.splice(index, 1);
                  users.unshift(obj);
                  break;
                }
              }
            }
            if (showNullUser) {
              showDivider += 1;
              users.unshift({
                beforeDivider: true,
                name: 'Unassigned',
                id: 0
              });
            }
            if (showAnyUser) {
              showDivider += 1;
              name = showAnyUser;
              if (name === true) {
                name = 'Any User';
              }
              anyUser = {
                beforeDivider: true,
                name: name,
                id: null
              };
              users.unshift(anyUser);
            }

            if (showDivider) {
              users.splice(showDivider, 0, 'divider');
            }

            if ($dropdown.hasClass('js-multiselect')) {
              const selected = getSelected().filter(i => i !== 0);

              if (selected.length > 0) {
                if ($dropdown.data('dropdownHeader')) {
                  showDivider += 1;
                  users.splice(showDivider, 0, {
                    header: $dropdown.data('dropdownHeader'),
                  });
                }

                const selectedUsers = users
                  .filter(u => selected.indexOf(u.id) !== -1)
                  .sort((a, b) => a.name > b.name);

                users = users.filter(u => selected.indexOf(u.id) === -1);

                selectedUsers.forEach((selectedUser) => {
                  showDivider += 1;
                  users.splice(showDivider, 0, selectedUser);
                });

                users.splice(showDivider + 1, 0, 'divider');
              }
            }
          }

          callback(users);
          if (showMenuAbove) {
            $dropdown.data('glDropdown').positionMenuAbove();
          }
        },
        filterable: true,
        filterRemote: true,
        search: {
          fields: ['name', 'username']
        },
        selectable: true,
        fieldName: $dropdown.data('fieldName'),
        toggleLabel: function(selected, el, glDropdown) {
          const inputValue = glDropdown.filterInput.val();

          if (this.multiSelect && inputValue === '') {
            // Remove non-users from the fullData array
            const users = glDropdown.filteredFullData();
            const callback = glDropdown.parseData.bind(glDropdown);

            // Update the data model
            this.processData(inputValue, users, callback);
          }

          if (this.multiSelect) {
            return getMultiSelectDropdownTitle(selected, $(el).hasClass('is-active'));
          }

          if (selected && 'id' in selected && $(el).hasClass('is-active')) {
            $dropdown.find('.dropdown-toggle-text').removeClass('is-default');
            if (selected.text) {
              return selected.text;
            } else {
              return selected.name;
            }
          } else {
            $dropdown.find('.dropdown-toggle-text').addClass('is-default');
            return defaultLabel;
          }
        },
        defaultLabel: defaultLabel,
        hidden: function(e) {
          if ($dropdown.hasClass('js-multiselect')) {
            emitSidebarEvent('sidebar.saveAssignees');
          }

          if (!$dropdown.data('alwaysShowSelectbox')) {
            $selectbox.hide();

            // Recalculate where .value is because vue might have changed it
            $block = $selectbox.closest('.block');
            $value = $block.find('.value');
            // display:block overrides the hide-collapse rule
            $value.css('display', '');
          }
        },
        multiSelect: $dropdown.hasClass('js-multiselect'),
        inputMeta: $dropdown.data('inputMeta'),
        clicked: function(options) {
          const { $el, e, isMarking } = options;
          const user = options.selectedObj;

          if ($dropdown.hasClass('js-multiselect')) {
            const isActive = $el.hasClass('is-active');
            const previouslySelected = $dropdown.closest('.selectbox')
                .find("input[name='" + ($dropdown.data('fieldName')) + "'][value!=0]");

            // Enables support for limiting the number of users selected
            // Automatically removes the first on the list if more users are selected
            checkMaxSelect();

            if (user.beforeDivider && user.name.toLowerCase() === 'unassigned') {
              // Unassigned selected
              previouslySelected.each((index, element) => {
                const id = parseInt(element.value, 10);
                element.remove();
              });
              emitSidebarEvent('sidebar.removeAllAssignees');
            } else if (isActive) {
              // user selected
              emitSidebarEvent('sidebar.addAssignee', user);

              // Remove unassigned selection (if it was previously selected)
              const unassignedSelected = $dropdown.closest('.selectbox')
                .find("input[name='" + ($dropdown.data('fieldName')) + "'][value=0]");

              if (unassignedSelected) {
                unassignedSelected.remove();
              }
            } else {
              if (previouslySelected.length === 0) {
              // Select unassigned because there is no more selected users
                this.addInput($dropdown.data('fieldName'), 0, {});
              }

              // User unselected
              emitSidebarEvent('sidebar.removeAssignee', user);
            }

            if (getSelected().find(u => u === gon.current_user_id)) {
              $('.assign-to-me-link').hide();
            } else {
              $('.assign-to-me-link').show();
            }
          }

          var isIssueIndex, isMRIndex, page, selected;
          page = $('body').attr('data-page');
          isIssueIndex = page === 'projects:issues:index';
          isMRIndex = (page === page && page === 'projects:merge_requests:index');
          if ($dropdown.hasClass('js-filter-bulk-update') || $dropdown.hasClass('js-issuable-form-dropdown')) {
            e.preventDefault();

            const isSelecting = (user.id !== selectedId);
            selectedId = isSelecting ? user.id : selectedIdDefault;

            if (selectedId === gon.current_user_id) {
              $('.assign-to-me-link').hide();
            } else {
              $('.assign-to-me-link').show();
            }
            return;
          }
          if ($el.closest('.add-issues-modal').length) {
            ModalStore.store.filter[$dropdown.data('fieldName')] = user.id;
          } else if (handleClick) {
            e.preventDefault();
            handleClick(user, isMarking);
          } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
            return Issuable.filterResults($dropdown.closest('form'));
          } else if ($dropdown.hasClass('js-filter-submit')) {
            return $dropdown.closest('form').submit();
          } else if (!$dropdown.hasClass('js-multiselect')) {
            selected = $dropdown.closest('.selectbox').find("input[name='" + ($dropdown.data('fieldName')) + "']").val();
            return assignTo(selected);
          }

          // Automatically close dropdown after assignee is selected
          // since CE has no multiple assignees
          // EE does not have a max-select
          if ($dropdown.data('maxSelect') &&
              getSelected().length === $dropdown.data('maxSelect')) {
            // Close the dropdown
            $dropdown.dropdown('toggle');
          }
        },
        id: function (user) {
          return user.id;
        },
        opened: function(e) {
          const $el = $(e.currentTarget);
          const selected = getSelected();
          if ($dropdown.hasClass('js-issue-board-sidebar') && selected.length === 0) {
            this.addInput($dropdown.data('fieldName'), 0, {});
          }
          $el.find('.is-active').removeClass('is-active');

          function highlightSelected(id) {
            $el.find(`li[data-user-id="${id}"] .dropdown-menu-user-link`).addClass('is-active');
          }

          if (selected.length > 0) {
            getSelected().forEach(selectedId => highlightSelected(selectedId));
          } else if ($dropdown.hasClass('js-issue-board-sidebar')) {
            highlightSelected(0);
          } else {
            highlightSelected(selectedId);
          }
        },
        updateLabel: $dropdown.data('dropdownTitle'),
        renderRow: function(user) {
          var avatar, img, listClosingTags, listWithName, listWithUserName, username;
          username = user.username ? "@" + user.username : "";
          avatar = user.avatar_url ? user.avatar_url : gon.default_avatar_url;

          let selected = false;

          if (this.multiSelect) {
            selected = getSelected().find(u => user.id === u);

            const fieldName = this.fieldName;
            const field = $dropdown.closest('.selectbox').find("input[name='" + fieldName + "'][value='" + user.id + "']");

            if (field.length) {
              selected = true;
            }
          } else {
            selected = user.id === selectedId;
          }

          img = "";
          if (user.beforeDivider != null) {
            `<li><a href='#' class='${selected === true ? 'is-active' : ''}'>${_.escape(user.name)}</a></li>`;
          } else {
            img = "<img src='" + avatar + "' class='avatar avatar-inline' width='32' />";
          }

          return `
            <li data-user-id=${user.id}>
              <a href='#' class='dropdown-menu-user-link ${selected === true ? 'is-active' : ''}'>
                ${img}
                <strong class='dropdown-menu-user-full-name'>
                  ${_.escape(user.name)}
                </strong>
                ${username ? `<span class='dropdown-menu-user-username'>${username}</span>` : ''}
              </a>
            </li>
          `;
        }
      });
    };
  })(this));
  $('.ajax-users-select').each((function(_this) {
    return function(i, select) {
      var firstUser, showAnyUser, showEmailUser, showNullUser;
      var options = {};
      options.skipLdap = $(select).hasClass('skip_ldap');
      options.projectId = $(select).data('projectId');
      options.groupId = $(select).data('groupId');
      options.showCurrentUser = $(select).data('currentUser');
      options.authorId = $(select).data('authorId');
      options.skipUsers = $(select).data('skipUsers');
      showNullUser = $(select).data('nullUser');
      showAnyUser = $(select).data('anyUser');
      showEmailUser = $(select).data('emailUser');
      firstUser = $(select).data('firstUser');
      return $(select).select2({
        placeholder: "Search for a user",
        multiple: $(select).hasClass('multiselect'),
        minimumInputLength: 0,
        query: function(query) {
          return _this.users(query.term, options, function(users) {
            var anyUser, data, emailUser, index, j, len, name, nullUser, obj, ref;
            data = {
              results: users
            };
            if (query.term.length === 0) {
              if (firstUser) {
                // Move current user to the front of the list
                ref = data.results;
                for (index = j = 0, len = ref.length; j < len; index = (j += 1)) {
                  obj = ref[index];
                  if (obj.username === firstUser) {
                    data.results.splice(index, 1);
                    data.results.unshift(obj);
                    break;
                  }
                }
              }
              if (showNullUser) {
                nullUser = {
                  name: 'Unassigned',
                  id: 0
                };
                data.results.unshift(nullUser);
              }
              if (showAnyUser) {
                name = showAnyUser;
                if (name === true) {
                  name = 'Any User';
                }
                anyUser = {
                  name: name,
                  id: null
                };
                data.results.unshift(anyUser);
              }
            }
            if (showEmailUser && data.results.length === 0 && query.term.match(/^[^@]+@[^@]+$/)) {
              var trimmed = query.term.trim();
              emailUser = {
                name: "Invite \"" + query.term + "\" by email",
                username: trimmed,
                id: trimmed,
                invite: true
              };
              data.results.unshift(emailUser);
            }
            return query.callback(data);
          });
        },
        initSelection: function() {
          var args;
          args = 1 <= arguments.length ? [].slice.call(arguments, 0) : [];
          return _this.initSelection.apply(_this, args);
        },
        formatResult: function() {
          var args;
          args = 1 <= arguments.length ? [].slice.call(arguments, 0) : [];
          return _this.formatResult.apply(_this, args);
        },
        formatSelection: function() {
          var args;
          args = 1 <= arguments.length ? [].slice.call(arguments, 0) : [];
          return _this.formatSelection.apply(_this, args);
        },
        dropdownCssClass: "ajax-users-dropdown",
        // we do not want to escape markup since we are displaying html in results
        escapeMarkup: function(m) {
          return m;
        }
      });
    };
  })(this));
}

UsersSelect.prototype.initSelection = function(element, callback) {
  var id, nullUser;
  id = $(element).val();
  if (id === "0") {
    nullUser = {
      name: 'Unassigned'
    };
    return callback(nullUser);
  } else if (id !== "") {
    return this.user(id, callback);
  }
};

UsersSelect.prototype.formatResult = function(user) {
  var avatar;
  if (user.avatar_url) {
    avatar = user.avatar_url;
  } else {
    avatar = gon.default_avatar_url;
  }
  return "<div class='user-result " + (!user.username ? 'no-username' : void 0) + "'> <div class='user-image'><img class='avatar avatar-inline s32' src='" + avatar + "'></div> <div class='user-name dropdown-menu-user-full-name'>" + _.escape(user.name) + "</div> <div class='user-username dropdown-menu-user-username'>" + (!user.invite ? "@" + _.escape(user.username) : "") + "</div> </div>";
};

UsersSelect.prototype.formatSelection = function(user) {
  return _.escape(user.name);
};

UsersSelect.prototype.user = function(user_id, callback) {
  if (!/^\d+$/.test(user_id)) {
    return false;
  }

  var url;
  url = this.buildUrl(this.userPath);
  url = url.replace(':id', user_id);
  return axios.get(url)
    .then(({ data }) => {
      callback(data);
    });
};

// Return users list. Filtered by query
// Only active users retrieved
UsersSelect.prototype.users = function(query, options, callback) {
  const url = this.buildUrl(this.usersPath);
  const params = {
    search: query,
    active: true,
    project_id: options.projectId || null,
    group_id: options.groupId || null,
    skip_ldap: options.skipLdap || null,
    todo_filter: options.todoFilter || null,
    todo_state_filter: options.todoStateFilter || null,
    current_user: options.showCurrentUser || null,
    author_id: options.authorId || null,
    skip_users: options.skipUsers || null
  };
  return axios.get(url, { params })
    .then(({ data }) => {
      callback(data);
    });
};

UsersSelect.prototype.buildUrl = function(url) {
  if (gon.relative_url_root != null) {
    url = gon.relative_url_root.replace(/\/$/, '') + url;
  }
  return url;
};

export default UsersSelect;
