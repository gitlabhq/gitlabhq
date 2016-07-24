(function() {
  $(function() {
    var groupFormatSelection, ldapGroupResult;
    ldapGroupResult = function(group) {
      return group.cn;
    };
    groupFormatSelection = function(group) {
      return group.cn;
    };
    $('.ajax-ldap-groups-select').each(function(i, select) {
      return $(select).select2({
        id: function(group) {
          return group.cn;
        },
        placeholder: "Search for a LDAP group",
        minimumInputLength: 1,
        query: function(query) {
          var provider;
          provider = $('#ldap_group_link_provider').val();
          return Api.ldap_groups(query.term, provider, function(groups) {
            var data;
            data = {
              results: groups
            };
            return query.callback(data);
          });
        },
        initSelection: function(element, callback) {
          var id;
          id = $(element).val();
          if (id !== "") {
            return callback({
              cn: id
            });
          }
        },
        formatResult: ldapGroupResult,
        formatSelection: groupFormatSelection,
        dropdownCssClass: "ajax-groups-dropdown",
        formatNoMatches: function(nomatch) {
          return "Match not found; try refining your search query.";
        }
      });
    });
    return $('#ldap_group_link_provider').on('change', function() {
      return $('.ajax-ldap-groups-select').select2('data', null);
    });
  });

}).call(this);
