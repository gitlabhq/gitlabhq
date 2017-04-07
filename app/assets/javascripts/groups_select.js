/* eslint-disable func-names, space-before-function-paren, no-var, wrap-iife, one-var, camelcase, one-var-declaration-per-line, quotes, object-shorthand, prefer-arrow-callback, comma-dangle, consistent-return, yoda, prefer-rest-params, prefer-spread, no-unused-vars, prefer-template, max-len */
/* global Api */

var slice = [].slice;

window.GroupsSelect = (function() {
  function GroupsSelect() {
    $('.ajax-groups-select').each((function(_this) {
      const self = _this;

      return function(i, select) {
        var all_available, skip_groups;
        const $select = $(select);
        all_available = $select.data('all-available');
        skip_groups = $select.data('skip-groups') || [];

        $select.select2({
          placeholder: "Search for a group",
          multiple: $select.hasClass('multiselect'),
          minimumInputLength: 0,
          ajax: {
            url: Api.buildUrl(Api.groupsPath),
            dataType: 'json',
            quietMillis: 250,
            transport: function (params) {
              $.ajax(params).then((data, status, xhr) => {
                const results = data || [];

                const headers = gl.utils.normalizeCRLFHeaders(xhr.getAllResponseHeaders());
                const currentPage = parseInt(headers['X-PAGE'], 10) || 0;
                const totalPages = parseInt(headers['X-TOTAL-PAGES'], 10) || 0;
                const more = currentPage < totalPages;

                return {
                  results,
                  pagination: {
                    more,
                  },
                };
              }).then(params.success).fail(params.error);
            },
            data: function (search, page) {
              return {
                search,
                page,
                per_page: GroupsSelect.PER_PAGE,
                all_available,
              };
            },
            results: function (data, page) {
              if (data.length) return { results: [] };

              const groups = data.length ? data : data.results || [];
              const more = data.pagination ? data.pagination.more : false;
              const results = groups.filter(group => skip_groups.indexOf(group.id) === -1);

              return {
                results,
                page,
                more,
              };
            },
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
            return self.formatResult.apply(self, args);
          },
          formatSelection: function() {
            var args;
            args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
            return self.formatSelection.apply(self, args);
          },
          dropdownCssClass: "ajax-groups-dropdown select2-infinite",
          // we do not want to escape markup since we are displaying html in results
          escapeMarkup: function(m) {
            return m;
          }
        });

        self.dropdown = document.querySelector('.select2-infinite .select2-results');

        $select.on('select2-loaded', self.forceOverflow.bind(self));
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
    return "<div class='group-result'> <div class='group-name'>" + group.full_name + "</div> <div class='group-path'>" + group.full_path + "</div> </div>";
  };

  GroupsSelect.prototype.formatSelection = function(group) {
    return group.full_name;
  };

  GroupsSelect.prototype.forceOverflow = function (e) {
    const itemHeight = this.dropdown.querySelector('.select2-result:first-child').clientHeight;
    this.dropdown.style.height = `${Math.floor(this.dropdown.scrollHeight - (itemHeight * 0.9))}px`;
  };

  GroupsSelect.PER_PAGE = 20;

  return GroupsSelect;
})();
