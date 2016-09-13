(function() {
  var slice = [].slice;

  this.GroupsSelect = (function() {
    function GroupsSelect() {
      $('.ajax-groups-select').each((function(_this) {
        return function(i, select) {
          var skip_group, url;
          skip_group = $(select).data("skip-group");
          url = $(select).data("url");
          return $(select).select2({
            placeholder: "Search for a group",
            multiple: $(select).hasClass('multiselect'),
            minimumInputLength: 0,
            query: function(query) {
              return $.ajax({
                url: url,
                data: {
                  search: query.term,
                  per_page: 20
                },
                dataType: "json"
              }).done(function(groups) {
                var data, group, j, len;
                data = {
                  results: []
                };
                for (j = 0, len = groups.length; j < len; j++) {
                  group = groups[j];
                  if (skip_group && group.path === skip_group) {
                    continue;
                  }
                  data.results.push(group);
                }
                return query.callback(data);
              });
            },
            initSelection: function(element, callback) {
              var id;
              id = $(element).val();
              if (id !== "") {
                return Api.group(id, callback);
              }
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
            dropdownCssClass: "ajax-groups-dropdown",
            // we do not want to escape markup since we are displaying html in results
            escapeMarkup: function(m) {
              return m;
            }
          });
        };
      })(this));
    }

    GroupsSelect.prototype.formatResult = function(group) {
      var avatar;
      if (group.avatar_url) {
        avatar = group.avatar_url;
      } else {
        avatar = gon.default_avatar_url;
      }
      return "<div class='group-result'> <div class='group-name'>" + group.name + "</div> <div class='group-path'>" + group.path + "</div> </div>";
    };

    GroupsSelect.prototype.formatSelection = function(group) {
      return group.name;
    };

    return GroupsSelect;

  })();

}).call(this);
