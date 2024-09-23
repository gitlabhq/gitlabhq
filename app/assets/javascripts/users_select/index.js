/* eslint-disable func-names, consistent-return, no-shadow, no-self-compare, no-unused-expressions, camelcase, no-param-reassign */
/* global Issuable */
/* global emitSidebarEvent */

import $ from 'jquery';
import { escape, template, uniqBy } from 'lodash';
import { AJAX_USERS_SELECT_PARAMS_MAP } from '~/users_select/constants';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import { isUserBusy } from '~/set_status_modal/utils';
import { fixTitle, dispose } from '~/tooltips';
import axios from '~/lib/utils/axios_utils';
import { parseBoolean, spriteIcon } from '~/lib/utils/common_utils';
import { s__, __, sprintf } from '~/locale';
import { getAjaxUsersSelectParams } from './utils';

// TODO: remove eventHub hack after code splitting refactor
window.emitSidebarEvent = window.emitSidebarEvent || $.noop;

function UsersSelect(currentUser, els, options = {}) {
  const elsClassName = els?.toString().match('.(.+$)')[1];
  const $els = $(els || '.js-user-search');
  this.users = this.users.bind(this);
  this.usersPath = '/-/autocomplete/users.json';
  if (currentUser != null) {
    if (typeof currentUser === 'object') {
      this.currentUser = currentUser;
    } else {
      this.currentUser = JSON.parse(currentUser);
    }
  }

  const { handleClick, states } = options;

  this.dropdowns = $els
    .map((i, dropdown) => {
      const userSelect = this;
      const $dropdown = $(dropdown);
      const options = {
        states,
        projectId: $dropdown.data('projectId'),
        groupId: $dropdown.data('groupId'),
        showCurrentUser: $dropdown.data('currentUser'),
        todoFilter: $dropdown.data('todoFilter'),
        todoStateFilter: $dropdown.data('todoStateFilter'),
        iid: $dropdown.data('iid'),
        issuableType: $dropdown.data('issuableType'),
        targetBranch: $dropdown.data('targetBranch'),
        authorId: $dropdown.data('authorId'),
        showSuggested: $dropdown.data('showSuggested'),
      };
      const showNullUser = $dropdown.data('nullUser');
      const defaultNullUser = $dropdown.data('nullUserDefault');
      const showMenuAbove = $dropdown.data('showMenuAbove');
      const showAnyUser = $dropdown.data('anyUser');
      const firstUser = $dropdown.data('firstUser');
      const defaultLabel = $dropdown.data('defaultLabel');
      const issueURL = $dropdown.data('issueUpdate');
      const $selectbox = $dropdown.closest('.selectbox');
      const $assignToMeLink = $selectbox.next('.assign-to-me-link');
      let $block = $selectbox.closest('.block');
      const abilityName = $dropdown.data('abilityName');
      let $value = $block.find('.value');
      const $collapsedSidebar = $block.find('.sidebar-collapsed-user');
      const $loading = $block.find('.block-loading').addClass('gl-hidden');
      const selectedIdDefault = defaultNullUser && showNullUser ? 0 : null;
      let selectedId = $dropdown.data('selected');
      let assignTo;
      let assigneeTemplate;
      let collapsedAssigneeTemplate;

      const suggestedReviewersHelpPath = $dropdown.data('suggestedReviewersHelpPath');
      const suggestedReviewersHeaderTemplate = template(
        `<div class="gl-flex gl-items-center">
         <%- header %>
         <a
           title="${s__('SuggestedReviewers|Learn about suggested reviewers')}"
           href="${suggestedReviewersHelpPath}"
           rel="noopener"
           target="_blank"
           aria-label="${s__('SuggestedReviewers|Suggested reviewers help link')}"
           class="hover:!gl-bg-transparent !gl-p-0 has-tooltip">
           ${spriteIcon('question-o', 'gl-ml-3 gl-icon s16')}
         </a>
       </div>`,
      );

      if (selectedId === undefined) {
        selectedId = selectedIdDefault;
      }

      const assignYourself = function () {
        const unassignedSelected = $dropdown
          .closest('.selectbox')
          .find(`input[name='${$dropdown.data('fieldName')}'][value=0]`);

        if (unassignedSelected) {
          unassignedSelected.remove();
        }

        // Save current selected user to the DOM
        const currentUserInfo = $dropdown.data('currentUserInfo') || {};
        const currentUser = userSelect.currentUser || {};
        const fieldName = $dropdown.data('fieldName');
        const userName = currentUserInfo.name;
        const userId = currentUserInfo.id || currentUser.id;

        const inputHtmlString = template(`
        <input type="hidden" name="<%- fieldName %>"
          data-meta="<%- userName %>"
          value="<%- userId %>" />
        `)({ fieldName, userName, userId });

        if ($selectbox) {
          $dropdown.parent().before(inputHtmlString);
        } else {
          $dropdown.after(inputHtmlString);
        }
      };

      if ($block[0]) {
        $block[0].addEventListener('assignYourself', assignYourself);
      }

      const getSelectedUserInputs = function () {
        return $selectbox.find(`input[name="${$dropdown.data('fieldName')}"]`);
      };

      const getSelected = function () {
        return getSelectedUserInputs()
          .map((index, input) => parseInt(input.value, 10))
          .get();
      };

      const checkMaxSelect = function () {
        const maxSelect = $dropdown.data('maxSelect');
        if (maxSelect) {
          const selected = getSelected();

          if (selected.length > maxSelect) {
            const firstSelectedId = selected[0];
            const firstSelected = $dropdown
              .closest('.selectbox')
              .find(`input[name='${$dropdown.data('fieldName')}'][value=${firstSelectedId}]`);

            firstSelected.remove();

            if ($dropdown.hasClass(elsClassName)) {
              emitSidebarEvent('sidebar.removeReviewer', {
                id: firstSelectedId,
              });
            } else {
              emitSidebarEvent('sidebar.removeAssignee', {
                id: firstSelectedId,
              });
            }
          }
        }
      };

      const getMultiSelectDropdownTitle = function (selectedUser, isSelected) {
        const selectedUsers = getSelected().filter((u) => u !== 0);

        const firstUser = getSelectedUserInputs()
          .map((index, input) => ({
            name: input.dataset.meta,
            value: parseInt(input.value, 10),
          }))
          .filter((u) => u.id !== 0)
          .get(0);

        if (selectedUsers.length === 0) {
          return s__('UsersSelect|Unassigned');
        }
        if (selectedUsers.length === 1) {
          return firstUser.name;
        }
        if (isSelected) {
          const otherSelected = selectedUsers.filter((s) => s !== selectedUser.id);
          return sprintf(s__('UsersSelect|%{name} + %{length} more'), {
            name: selectedUser.name,
            length: otherSelected.length,
          });
        }
        return sprintf(s__('UsersSelect|%{name} + %{length} more'), {
          name: firstUser.name,
          length: selectedUsers.length - 1,
        });
      };

      $assignToMeLink.on('click', (e) => {
        e.preventDefault();
        $(e.currentTarget).hide();

        if ($dropdown.data('multiSelect')) {
          assignYourself();
          checkMaxSelect();

          const currentUserInfo = $dropdown.data('currentUserInfo');
          $dropdown
            .find('.dropdown-toggle-text')
            .text(getMultiSelectDropdownTitle(currentUserInfo))
            .removeClass('is-default');
        } else {
          const $input = $(`input[name="${$dropdown.data('fieldName')}"]`);
          $input.val(gon.current_user_id);
          selectedId = $input.val();
          $dropdown
            .find('.dropdown-toggle-text')
            .text(gon.current_user_fullname)
            .removeClass('is-default');
        }
      });

      $block.on('click', '.js-assign-yourself', (e) => {
        e.preventDefault();
        return assignTo(userSelect.currentUser.id);
      });

      assignTo = function (selected) {
        const data = {};
        data[abilityName] = {};
        data[abilityName].assignee_id = selected != null ? selected : null;
        $loading.removeClass('gl-hidden');
        $dropdown.trigger('loading.gl.dropdown');

        return axios.put(issueURL, data).then(({ data }) => {
          let user = {};
          let tooltipTitle;
          $dropdown.trigger('loaded.gl.dropdown');
          $loading.addClass('gl-hidden');
          if (data.assignee) {
            user = {
              name: data.assignee.name,
              username: data.assignee.username,
              avatar: data.assignee.avatar_url,
            };
            tooltipTitle = escape(user.name);
          } else {
            user = {
              name: s__('UsersSelect|Unassigned'),
              username: '',
              avatar: '',
            };
            tooltipTitle = s__('UsersSelect|Assignee');
          }
          $value.html(assigneeTemplate(user));
          $collapsedSidebar.attr('title', tooltipTitle);
          fixTitle($collapsedSidebar);

          return $collapsedSidebar.html(collapsedAssigneeTemplate(user));
        });
      };
      collapsedAssigneeTemplate = template(
        `<% if( avatar ) { %> <a class="author-link" href="/<%- username %>"> <img width="24" class="avatar avatar-inline s24" alt="" src="<%- avatar %>"> </a> <% } else { %> ${spriteIcon(
          'user',
        )} <% } %>`,
      );
      assigneeTemplate = template(
        `<% if (username) { %> <a class="author-link gl-font-bold" href="/<%- username %>"> <% if( avatar ) { %> <img width="32" class="avatar avatar-inline s32" alt="" src="<%- avatar %>"> <% } %> <span class="author"><%- name %></span> <span class="username"> @<%- username %> </span> </a> <% } else { %> <span class="no-value assign-yourself">
      ${sprintf(s__('UsersSelect|No assignee - %{openingTag} assign yourself %{closingTag}'), {
        openingTag: '<a href="#" class="js-assign-yourself">',
        closingTag: '</a>',
      })}</span> <% } %>`,
      );

      return initDeprecatedJQueryDropdown($dropdown, {
        showMenuAbove,
        data(term, callback) {
          return userSelect.users(term, options, (users) => {
            // GitLabDropdownFilter returns this.instance
            // GitLabDropdownRemote returns this.options.instance
            const deprecatedJQueryDropdown = this.instance || this.options.instance;
            deprecatedJQueryDropdown.options.processData(term, users, callback);
          });
        },
        processData(term, dataArg, callback) {
          // Sometimes the `dataArg` can contain special dropdown items like
          // dividers which we don't want to consider here.
          const data = dataArg.filter((x) => !x.type);

          let users = data;

          // Only show assigned user list when there is no search term
          if ($dropdown.hasClass('js-multiselect') && term.length === 0) {
            const selectedInputs = getSelectedUserInputs();

            // Potential duplicate entries when dealing with issue board
            // because issue board is also managed by vue
            const selectedUsers = uniqBy(selectedInputs, (a) => a.value)
              .filter((input) => {
                const userId = parseInt(input.value, 10);
                const inUsersArray = users.find((u) => u.id === userId);

                return !inUsersArray && userId !== 0;
              })
              .map((input) => {
                const userId = parseInt(input.value, 10);
                const {
                  avatarUrl,
                  avatar_url,
                  name,
                  username,
                  can_merge: canMerge,
                } = input.dataset;
                return {
                  avatar_url: avatarUrl || avatar_url || gon.default_avatar_url,
                  id: userId,
                  name,
                  username,
                  can_merge: parseBoolean(canMerge),
                };
              });

            users = data.concat(selectedUsers);
          }

          let anyUser;
          let index;
          let len;
          let name;
          let obj;
          let showDivider;
          if (term.length === 0) {
            showDivider = 0;
            if (firstUser) {
              // Move current user to the front of the list
              for (index = 0, len = users.length; index < len; index += 1) {
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
                name: s__('UsersSelect|Unassigned'),
                id: 0,
              });
            }
            if (showAnyUser) {
              showDivider += 1;
              name = showAnyUser;
              if (name === true) {
                name = s__('UsersSelect|Any User');
              }
              anyUser = {
                beforeDivider: true,
                name,
                id: null,
              };
              users.unshift(anyUser);
            }

            if (showDivider) {
              users.splice(showDivider, 0, { type: 'divider' });
            }

            if ($dropdown.hasClass('js-multiselect')) {
              const selected = getSelected().filter((i) => i !== 0);

              if ($dropdown.data('showSuggested')) {
                const suggested = this.suggestedUsers(users);
                if (suggested.length) {
                  users = users.filter(
                    (u) => !u.suggested || (u.suggested && selected.indexOf(u.id) !== -1),
                  );
                  users.splice(showDivider + 1, 0, ...suggested);
                }
              }

              if (selected.length > 0) {
                if ($dropdown.data('dropdownHeader')) {
                  showDivider += 1;
                  users.splice(showDivider, 0, {
                    type: 'header',
                    content: $dropdown.data('dropdownHeader'),
                  });
                }

                const selectedUsers = users
                  .filter((u) => selected.indexOf(u.id) !== -1)
                  .sort((a, b) => a.name > b.name);

                users = users.filter((u) => selected.indexOf(u.id) === -1);

                selectedUsers.forEach((selectedUser) => {
                  showDivider += 1;
                  users.splice(showDivider, 0, selectedUser);
                });

                users.splice(showDivider + 1, 0, { type: 'divider' });
              }
            }
          }

          callback(users);
          if (showMenuAbove) {
            $dropdown.data('deprecatedJQueryDropdown').positionMenuAbove();
          }
        },
        suggestedUsers(users) {
          const selected = getSelected().filter((i) => i !== 0);
          const suggestedUsers = users.filter((u) => u.suggested && selected.indexOf(u.id) === -1);

          if (!suggestedUsers.length) return [];

          const items = [
            {
              type: 'header',
              content: suggestedReviewersHeaderTemplate({
                header: $dropdown.data('suggestedReviewersHeader'),
              }),
            },
            ...suggestedUsers,
            { type: 'header', content: $dropdown.data('allMembersHeader') },
          ];
          return items;
        },
        filterable: true,
        filterRemote: true,
        search: {
          fields: ['name', 'username'],
        },
        selectable: true,
        fieldName: $dropdown.data('fieldName'),
        toggleLabel(selected, el, deprecatedJQueryDropdown) {
          const inputValue = deprecatedJQueryDropdown.filterInput.val();

          if (this.multiSelect && inputValue === '') {
            // Remove non-users from the fullData array
            const users = deprecatedJQueryDropdown.filteredFullData();
            const callback = deprecatedJQueryDropdown.parseData.bind(deprecatedJQueryDropdown);

            // Update the data model
            this.processData(inputValue, users, callback);
          }

          deprecatedJQueryDropdown.filter.clear();

          if (this.multiSelect) {
            return getMultiSelectDropdownTitle(selected, $(el).hasClass('is-active'));
          }

          if (selected && 'id' in selected && $(el).hasClass('is-active')) {
            $dropdown.find('.dropdown-toggle-text').removeClass('is-default');
            if (selected.text) {
              return selected.text;
            }
            return selected.name;
          }
          $dropdown.find('.dropdown-toggle-text').addClass('is-default');

          return defaultLabel;
        },
        defaultLabel,
        hidden() {
          if ($dropdown.hasClass('js-multiselect')) {
            if ($dropdown.hasClass(elsClassName)) {
              if (!$dropdown.closest('.merge-request-form').length) {
                $dropdown.data('deprecatedJQueryDropdown').clearMenu();
                $dropdown.closest('.selectbox').children('input[type="hidden"]').remove();
              }
              emitSidebarEvent('sidebar.saveReviewers');
            } else {
              emitSidebarEvent('sidebar.saveAssignees');
            }
          }

          if (!$dropdown.data('alwaysShowSelectbox')) {
            $selectbox.hide();

            // Recalculate where .value is because vue might have changed it
            $block = $selectbox.closest('.block');
            $value = $block.find('.value');
            // display:block overrides the hide-collapse rule
            $value.css('display', '');
          }

          $('.dropdown-input-field', $block).val('');
        },
        multiSelect: $dropdown.hasClass('js-multiselect'),
        inputMeta: $dropdown.data('inputMeta'),
        clicked(options) {
          const { $el, e, isMarking } = options;
          const user = options.selectedObj;

          dispose($el);

          if ($dropdown.hasClass('js-multiselect')) {
            const isActive = $el.hasClass('is-active');
            const previouslySelected = $dropdown
              .closest('.selectbox')
              .find(`input[name='${$dropdown.data('fieldName')}'][value!=0]`);

            // Enables support for limiting the number of users selected
            // Automatically removes the first on the list if more users are selected
            checkMaxSelect();

            if (user.beforeDivider && user.name.toLowerCase() === 'unassigned') {
              // Unassigned selected
              previouslySelected.each((index, element) => {
                element.remove();
              });
              if ($dropdown.hasClass(elsClassName)) {
                emitSidebarEvent('sidebar.removeAllReviewers');
              } else {
                emitSidebarEvent('sidebar.removeAllAssignees');
              }
            } else if (isActive) {
              // user selected
              if ($dropdown.hasClass(elsClassName)) {
                emitSidebarEvent('sidebar.addReviewer', user);
              } else {
                emitSidebarEvent('sidebar.addAssignee', user);
              }

              // Remove unassigned selection (if it was previously selected)
              const unassignedSelected = $dropdown
                .closest('.selectbox')
                .find(`input[name='${$dropdown.data('fieldName')}'][value=0]`);

              if (unassignedSelected) {
                unassignedSelected.remove();
              }
            } else {
              if (previouslySelected.length === 0) {
                // Select unassigned because there is no more selected users
                this.addInput($dropdown.data('fieldName'), 0, {});
              }

              // User unselected
              if ($dropdown.hasClass(elsClassName)) {
                emitSidebarEvent('sidebar.removeReviewer', user);
              } else {
                emitSidebarEvent('sidebar.removeAssignee', user);
              }
            }

            if (getSelected().find((u) => u === gon.current_user_id)) {
              $assignToMeLink.hide();
            } else {
              $assignToMeLink.show();
            }
          }

          const page = $('body').attr('data-page');
          const isIssueIndex = page === 'projects:issues:index';
          const isMRIndex = page === page && page === 'projects:merge_requests:index';
          if (
            $dropdown.hasClass('js-filter-bulk-update') ||
            $dropdown.hasClass('js-issuable-form-dropdown')
          ) {
            e.preventDefault();

            const isSelecting = user.id !== selectedId;
            selectedId = isSelecting ? user.id : selectedIdDefault;

            if (selectedId === gon.current_user_id) {
              $('.assign-to-me-link').hide();
            } else {
              $('.assign-to-me-link').show();
            }
            return;
          }
          if (handleClick) {
            e.preventDefault();
            handleClick(user, isMarking);
          } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
            return Issuable.filterResults($dropdown.closest('form'));
          } else if ($dropdown.hasClass('js-filter-submit')) {
            return $dropdown.closest('form').submit();
          } else if (!$dropdown.hasClass('js-multiselect')) {
            const selected = $dropdown
              .closest('.selectbox')
              .find(`input[name='${$dropdown.data('fieldName')}']`)
              .val();
            return assignTo(selected);
          }

          // Automatically close dropdown after assignee is selected
          // since CE has no multiple assignees
          // EE does not have a max-select
          if ($dropdown.data('maxSelect') && getSelected().length === $dropdown.data('maxSelect')) {
            // Close the dropdown
            $dropdown.dropdown('toggle');
          }
        },
        id(user) {
          return user.id;
        },
        opened(e) {
          const $el = $(e.currentTarget);
          const selected = getSelected();
          $el.find('.is-active').removeClass('is-active');

          function highlightSelected(id) {
            $el.find(`li[data-user-id="${id}"] .dropdown-menu-user-link`).addClass('is-active');
          }

          if (selected.length > 0) {
            getSelected().forEach((selectedId) => highlightSelected(selectedId));
          } else {
            highlightSelected(selectedId);
          }
        },
        updateLabel: $dropdown.data('dropdownTitle'),
        renderRow(user) {
          const username = user.username ? `@${user.username}` : '';
          const avatar = user.avatar_url ? user.avatar_url : gon.default_avatar_url;

          let selected = false;

          if (this.multiSelect) {
            selected = getSelected().find((u) => user.id === u);

            const { fieldName } = this;
            const field = $dropdown
              .closest('.selectbox')
              .find(`input[name='${fieldName}'][value='${user.id}']`);

            if (field.length) {
              selected = true;
            }
          } else {
            selected = user.id === selectedId;
          }

          let img = '';
          if (user.beforeDivider != null) {
            `<li><a href='#' class='${selected === true ? 'is-active' : ''}'>${escape(
              user.name,
            )}</a></li>`;
          } else {
            // 0 margin, because it's now handled by a wrapper
            img = `<img src='${avatar}' alt='' class='avatar avatar-inline !gl-m-0' width='32' />`;
          }

          return userSelect.renderRow(
            options.issuableType,
            user,
            selected,
            username,
            img,
            elsClassName,
          );
        },
      })
        .get()
        .map((dropdown) => dropdown.GitLabDropdownInstance);
    })
    .get();
}

// Return users list. Filtered by query
// Only active users retrieved
UsersSelect.prototype.users = function (query, options, callback) {
  const url = this.buildUrl(this.usersPath);
  const params = {
    search: query,
    active: true,
    ...getAjaxUsersSelectParams(options, AJAX_USERS_SELECT_PARAMS_MAP),
  };

  const isMergeRequest = options.issuableType === TYPE_MERGE_REQUEST;
  const isEditMergeRequest = !options.issuableType && options.iid && options.targetBranch;
  const isNewMergeRequest = !options.issuableType && !options.iid && options.targetBranch;

  if (isMergeRequest || isEditMergeRequest || isNewMergeRequest) {
    params.merge_request_iid = options.iid || null;
    params.approval_rules = true;
  }

  if (isMergeRequest && options.showSuggested) {
    params.show_suggested = true;
  }

  if (isNewMergeRequest) {
    params.target_branch = options.targetBranch || null;
  }

  return axios.get(url, { params }).then(({ data }) => {
    callback(data);
  });
};

UsersSelect.prototype.buildUrl = function (url) {
  if (gon.relative_url_root != null) {
    url = gon.relative_url_root.replace(/\/$/, '') + url;
  }
  return url;
};

// eslint-disable-next-line max-params
UsersSelect.prototype.renderRow = function (
  issuableType,
  user,
  selected,
  username,
  img,
  elsClassName,
) {
  const tooltip = issuableType === TYPE_MERGE_REQUEST && !user.can_merge ? __('Cannot merge') : '';
  const tooltipClass = tooltip ? `has-tooltip` : '';
  const selectedClass = selected === true ? 'is-active' : '';
  const linkClasses = `${selectedClass} ${tooltipClass}`;
  const tooltipAttributes = tooltip
    ? `data-container="body" data-placement="left" data-title="${tooltip}"`
    : '';
  const dataUserSuggested = user.suggested ? `data-user-suggested=${user.suggested}` : '';

  const busyBadge =
    user?.availability && isUserBusy(user.availability)
      ? `<span class="badge badge-warning badge-pill gl-badge sm">${__('Busy')}</span>`
      : '';
  return `
    <li data-user-id=${user.id} ${dataUserSuggested}>
      <a href="#" class="dropdown-menu-user-link !gl-flex gl-items-center ${linkClasses}" ${tooltipAttributes}>
        ${this.renderRowAvatar(issuableType, user, img)}
        <span class="gl-flex gl-flex-col gl-overflow-hidden">
          <strong class="dropdown-menu-user-full-name gl-font-bold">
            ${escape(user.name)}
            ${busyBadge}
          </strong>
          ${
            username
              ? `<span class="dropdown-menu-user-username gl-text-subtle">${escape(
                  username,
                )}</span>`
              : ''
          }
          ${this.renderApprovalRules(elsClassName, user.applicable_approval_rules)}
        </span>
      </a>
    </li>
  `;
};

UsersSelect.prototype.renderRowAvatar = function (issuableType, user, img) {
  if (user.beforeDivider) {
    return img;
  }

  const mergeIcon =
    issuableType === TYPE_MERGE_REQUEST && !user.can_merge
      ? spriteIcon('warning-solid', 's12 merge-icon')
      : '';

  return `<span class="gl-relative gl-mr-3">
    ${img}
    ${mergeIcon}
  </span>`;
};

UsersSelect.prototype.renderApprovalRules = function (elsClassName, approvalRules = []) {
  const count = approvalRules.length;

  if (!elsClassName?.includes('reviewer') || !count) {
    return '';
  }

  const [rule] = approvalRules;
  const countText = sprintf(__('(+%{count}&nbsp;rules)'), { count });
  const renderApprovalRulesCount = count > 1 ? `<span class="gl-ml-2">${countText}</span>` : '';
  const ruleName = rule.rule_type === 'code_owner' ? __('Code Owner') : escape(rule.name);

  return `<div class="gl-flex gl-text-sm">
    <span class="gl-truncate" title="${ruleName}">${ruleName}</span>
    ${renderApprovalRulesCount}
  </div>`;
};

export default UsersSelect;
