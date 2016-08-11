// Modified version of `UsersSelect` for use with access selection for protected branches.
//
// - Selections are sent via AJAX if `saveOnSelect` is `true`
// - If `saveOnSelect` is `false`, the dropdown element must have a `field-name` data
//   attribute. The DOM must contain two fields - "#{field-name}[access_level]" and "#{field_name}[user_id]"
//   where the selections will be stored.

class ProtectedBranchesAccessSelect {
  constructor(container, saveOnSelect, selectDefault) {
    this.container = container;
    this.saveOnSelect = saveOnSelect;
    this.selectDefault = selectDefault;
    this.usersPath = "/autocomplete/users.json";
    this.setupDropdown(".allowed-to-merge", gon.merge_access_levels, gon.selected_merge_access_levels);
    this.setupDropdown(".allowed-to-push", gon.push_access_levels, gon.selected_push_access_levels);
  }

  setupDropdown(className, accessLevels, selectedAccessLevels) {
    this.container.find(className).each((i, element) => {
      var dropdown = $(element).glDropdown({
        clicked: _.chain(this.onSelect).partial(element).bind(this).value(),
        data: (term, callback) => {
          this.getUsers(term, (users) => {
            users = _(users).map((user) => _(user).extend({ type: "user" }));
            accessLevels = _(accessLevels).map((accessLevel) => _(accessLevel).extend({ type: "role" }));
            var accessLevelsWithUsers = accessLevels.concat("divider", users);
            callback(_(accessLevelsWithUsers).reject((item) => _.contains(selectedAccessLevels, item.id)));
          });
        },
        filterable: true,
        filterRemote: true,
        search: { fields: ['name', 'username'] },
        selectable: true,
        toggleLabel: (selected) => $(element).data('default-label'),
        renderRow: (user) => {
          if (user.before_divider != null) {
            return "<li> <a href='#'>" + user.text + " </a> </li>";
          }


          var username = user.username ? "@" + user.username : null;
          var avatar = user.avatar_url ? user.avatar_url : false;
          var img = avatar ? "<img src='" + avatar + "' class='avatar avatar-inline' width='30' />" : '';

          var listWithName = "<li> <a href='#' class='dropdown-menu-user-link'> " + img + " <strong class='dropdown-menu-user-full-name'> " + user.name + " </strong>";
          var listWithUserName = username ? "<span class='dropdown-menu-user-username'> " + username + " </span>" : '';
          var listClosingTags = "</a> </li>";

          return listWithName + listWithUserName + listClosingTags;
        }
      });

      if (this.selectDefault) {
        $(dropdown).find('.dropdown-toggle-text').text(accessLevels[0].text);
      }
    });
  }

  onSelect(dropdown, selected, element, e) {
    $(dropdown).find('.dropdown-toggle-text').text(selected.text || selected.name);

    var access_level = selected.type == 'user' ? 40 : selected.id;
    var user_id = selected.type == 'user' ? selected.id : null;

    if (this.saveOnSelect) {
      $.ajax({
        type: "POST",
        url: $(dropdown).data('url'),
        dataType: "json",
        data: {
          _method: 'PATCH',
          id: $(dropdown).data('id'),
          protected_branch: {
            ["" + ($(dropdown).data('type')) + "_attributes"]: [{
              access_level: access_level,
              user_id: user_id
            }]
          }
        },
        success: function() {
          var row;
          row = $(e.target);
          row.closest('tr').effect('highlight');
          row.closest('td').find('.access-levels-list').append("<li>" + selected.name + "</li>");
          location.reload();
        },
        error: function() {
          new Flash("Failed to update branch!", "alert");
        }
      });
    } else {
      var fieldName = $(dropdown).data('field-name');
      $("input[name='" + fieldName + "[access_level]']").val(access_level);
      $("input[name='" + fieldName + "[user_id]']").val(user_id);
    }
  }

  getUsers(query, callback) {
    var url = this.buildUrl(this.usersPath);
    return $.ajax({
      url: url,
      data: {
        search: query,
        per_page: 20,
        active: true,
        project_id: gon.current_project_id
      },
      dataType: "json"
    }).done(function(users) {
      callback(users);
    });
  }

  buildUrl(url) {
    if (gon.relative_url_root != null) {
      url = gon.relative_url_root.replace(/\/$/, '') + url;
    }
    return url;
  }
}
