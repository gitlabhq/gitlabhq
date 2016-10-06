(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    slice = [].slice;

  this.UsersSelect = (function() {
    function UsersSelect(currentUser) {
      this.users = bind(this.users, this);
      this.user = bind(this.user, this);
      this.usersPath = "/autocomplete/users.json";
      this.userPath = "/autocomplete/users/:id.json";
      if (currentUser != null) {
        if (typeof currentUser === 'object') {
          this.currentUser = currentUser;
        } else {
          this.currentUser = JSON.parse(currentUser);
        }
      }
      $('.js-user-search').each((function(_this) {
        return function(i, dropdown) {
          var options = {};
          var $block, $collapsedSidebar, $dropdown, $loading, $selectbox, $value, abilityName, assignTo, assigneeTemplate, collapsedAssigneeTemplate, defaultLabel, firstUser, issueURL, selectedId, showAnyUser, showNullUser, showMenuAbove;
          $dropdown = $(dropdown);
          options.projectId = $dropdown.data('project-id');
          options.showCurrentUser = $dropdown.data('current-user');
          showNullUser = $dropdown.data('null-user');
          showMenuAbove = $dropdown.data('showMenuAbove');
          showAnyUser = $dropdown.data('any-user');
          firstUser = $dropdown.data('first-user');
          options.authorId = $dropdown.data('author-id');
          selectedId = $dropdown.data('selected');
          defaultLabel = $dropdown.data('default-label');
          issueURL = $dropdown.data('issueUpdate');
          $selectbox = $dropdown.closest('.selectbox');
          $block = $selectbox.closest('.block');
          abilityName = $dropdown.data('ability-name');
          $value = $block.find('.value');
          $collapsedSidebar = $block.find('.sidebar-collapsed-user');
          $loading = $block.find('.block-loading').fadeOut();

          var updateIssueBoardsIssue = function () {
            $loading.fadeIn();
            gl.issueBoards.BoardsStore.detail.issue.update(issueURL)
              .then(function () {
                $loading.fadeOut();
              });
          };

          $block.on('click', '.js-assign-yourself', function(e) {
            e.preventDefault();

            if ($dropdown.hasClass('js-issue-board-assignee')) {
              Vue.set(gl.issueBoards.BoardsStore.detail.issue, 'assignee', new ListUser({
                id: _this.currentUser.id,
                username: _this.currentUser.username,
                name: _this.currentUser.name,
                avatar_url: _this.currentUser.avatar_url
              }));

              updateIssueBoardsIssue();
            } else {
              return assignTo(_this.currentUser.id);
            }
          });
          assignTo = function(selected) {
            var data;
            data = {};
            data[abilityName] = {};
            data[abilityName].assignee_id = selected != null ? selected : null;
            $loading.fadeIn();
            $dropdown.trigger('loading.gl.dropdown');
            return $.ajax({
              type: 'PUT',
              dataType: 'json',
              url: issueURL,
              data: data
            }).done(function(data) {
              var user;
              $dropdown.trigger('loaded.gl.dropdown');
              $loading.fadeOut();
              $selectbox.hide();
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
              $collapsedSidebar.attr('title', user.name).tooltip('fixTitle');
              return $collapsedSidebar.html(collapsedAssigneeTemplate(user));
            });
          };
          collapsedAssigneeTemplate = _.template('<% if( avatar ) { %> <a class="author_link" href="/<%- username %>"> <img width="24" class="avatar avatar-inline s24" alt="" src="<%- avatar %>"> </a> <% } else { %> <i class="fa fa-user"></i> <% } %>');
          assigneeTemplate = _.template('<% if (username) { %> <a class="author_link bold" href="/<%- username %>"> <% if( avatar ) { %> <img width="32" class="avatar avatar-inline s32" alt="" src="<%- avatar %>"> <% } %> <span class="author"><%- name %></span> <span class="username"> @<%- username %> </span> </a> <% } else { %> <span class="no-value assign-yourself"> No assignee - <a href="#" class="js-assign-yourself"> assign yourself </a> </span> <% } %>');
          return $dropdown.glDropdown({
            showMenuAbove: showMenuAbove,
            data: function(term, callback) {
              var isAuthorFilter;
              isAuthorFilter = $('.js-author-search');
              return _this.users(term, options, function(users) {
                var anyUser, index, j, len, name, obj, showDivider;
                if (term.length === 0) {
                  showDivider = 0;
                  if (firstUser) {
                    // Move current user to the front of the list
                    for (index = j = 0, len = users.length; j < len; index = ++j) {
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
                }
                if (showDivider) {
                  users.splice(showDivider, 0, "divider");
                }

                callback(users);
                if (showMenuAbove) {
                  $dropdown.data('glDropdown').positionMenuAbove();
                }
              });
            },
            filterable: true,
            filterRemote: true,
            search: {
              fields: ['name', 'username']
            },
            selectable: true,
            fieldName: $dropdown.data('field-name'),
            toggleLabel: function(selected, el) {
              if (selected && 'id' in selected && $(el).hasClass('is-active')) {
                if (selected.text) {
                  return selected.text;
                } else {
                  return selected.name;
                }
              } else {
                return defaultLabel;
              }
            },
            defaultLabel: defaultLabel,
            inputId: 'issue_assignee_id',
            hidden: function(e) {
              $selectbox.hide();
              // display:block overrides the hide-collapse rule
              return $value.css('display', '');
            },
            vue: $dropdown.hasClass('js-issue-board-sidebar'),
            clicked: function(user, $el, e) {
              var isIssueIndex, isMRIndex, page, selected;
              page = $('body').data('page');
              isIssueIndex = page === 'projects:issues:index';
              isMRIndex = (page === page && page === 'projects:merge_requests:index');
              if ($dropdown.hasClass('js-filter-bulk-update') || $dropdown.hasClass('js-issuable-form-dropdown')) {
                e.preventDefault();
                selectedId = user.id;
                return;
              }
              if (page === 'projects:boards:show' && !$dropdown.hasClass('js-issue-board-sidebar')) {
                selectedId = user.id;
                gl.issueBoards.BoardsStore.state.filters[$dropdown.data('field-name')] = user.id;
                gl.issueBoards.BoardsStore.updateFiltersUrl();
                e.preventDefault();
              } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
                selectedId = user.id;
                return Issuable.filterResults($dropdown.closest('form'));
              } else if ($dropdown.hasClass('js-filter-submit')) {
                return $dropdown.closest('form').submit();
              } else if ($dropdown.hasClass('js-issue-board-sidebar')) {
                if (user.id) {
                  Vue.set(gl.issueBoards.BoardsStore.detail.issue, 'assignee', new ListUser({
                    id: user.id,
                    username: user.username,
                    name: user.name,
                    avatar_url: user.avatar_url
                  }));
                } else {
                  Vue.delete(gl.issueBoards.BoardsStore.detail.issue, 'assignee');
                }

                updateIssueBoardsIssue();
              } else {
                selected = $dropdown.closest('.selectbox').find("input[name='" + ($dropdown.data('field-name')) + "']").val();
                return assignTo(selected);
              }
            },
            id: function (user) {
              return user.id;
            },
            renderRow: function(user) {
              var avatar, img, listClosingTags, listWithName, listWithUserName, selected, username;
              username = user.username ? "@" + user.username : "";
              avatar = user.avatar_url ? user.avatar_url : false;
              selected = user.id === selectedId ? "is-active" : "";
              img = "";
              if (user.beforeDivider != null) {
                "<li> <a href='#' class='" + selected + "'> " + user.name + " </a> </li>";
              } else {
                if (avatar) {
                  img = "<img src='" + avatar + "' class='avatar avatar-inline' width='30' />";
                }
              }
              // split into three parts so we can remove the username section if nessesary
              listWithName = "<li> <a href='#' class='dropdown-menu-user-link " + selected + "'> " + img + " <strong class='dropdown-menu-user-full-name'> " + user.name + " </strong>";
              listWithUserName = "<span class='dropdown-menu-user-username'> " + username + " </span>";
              listClosingTags = "</a> </li>";
              if (username === '') {
                listWithUserName = '';
              }
              return listWithName + listWithUserName + listClosingTags;
            }
          });
        };
      })(this));
      $('.ajax-users-select').each((function(_this) {
        return function(i, select) {
          var firstUser, showAnyUser, showEmailUser, showNullUser;
          var options = {};
          options.skipLdap = $(select).hasClass('skip_ldap');
          options.projectId = $(select).data('project-id');
          options.groupId = $(select).data('group-id');
          options.showCurrentUser = $(select).data('current-user');
          options.pushCodeToProtectedBranches = $(select).data('push-code-to-protected-branches');
          options.authorId = $(select).data('author-id');
          options.skipUsers = $(select).data('skip-users');
          showNullUser = $(select).data('null-user');
          showAnyUser = $(select).data('any-user');
          showEmailUser = $(select).data('email-user');
          firstUser = $(select).data('first-user');
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
                    for (index = j = 0, len = ref.length; j < len; index = ++j) {
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
                  emailUser = {
                    name: "Invite \"" + query.term + "\"",
                    username: query.term,
                    id: query.term
                  };
                  data.results.unshift(emailUser);
                }
                return query.callback(data);
              });
            },
            initSelection: function() {
              var args;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
              return _this.initSelection.apply(_this, args);
            },
            formatResult: function() {
              var args;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
              return _this.formatResult.apply(_this, args);
            },
            formatSelection: function() {
              var args;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
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
      return "<div class='user-result " + (!user.username ? 'no-username' : void 0) + "'> <div class='user-image'><img class='avatar s24' src='" + avatar + "'></div> <div class='user-name'>" + user.name + "</div> <div class='user-username'>" + (user.username || "") + "</div> </div>";
    };

    UsersSelect.prototype.formatSelection = function(user) {
      return user.name;
    };

    UsersSelect.prototype.user = function(user_id, callback) {
      var url;
      url = this.buildUrl(this.userPath);
      url = url.replace(':id', user_id);
      return $.ajax({
        url: url,
        dataType: "json"
      }).done(function(user) {
        return callback(user);
      });
    };

    // Return users list. Filtered by query
    // Only active users retrieved
    UsersSelect.prototype.users = function(query, options, callback) {
      var url;
      url = this.buildUrl(this.usersPath);
      return $.ajax({
        url: url,
        data: {
          search: query,
          per_page: 20,
          active: true,
          project_id: options.projectId || null,
          group_id: options.groupId || null,
          skip_ldap: options.skipLdap || null,
          current_user: options.showCurrentUser || null,
          push_code_to_protected_branches: options.pushCodeToProtectedBranches || null,
          author_id: options.authorId || null,
          skip_users: options.skipUsers || null
        },
        dataType: "json"
      }).done(function(users) {
        return callback(users);
      });
    };

    UsersSelect.prototype.buildUrl = function(url) {
      if (gon.relative_url_root != null) {
        url = gon.relative_url_root.replace(/\/$/, '') + url;
      }
      return url;
    };

    return UsersSelect;

  })();

}).call(this);
