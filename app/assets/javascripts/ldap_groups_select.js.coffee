$ ->
  ldapGroupResult = (group) ->
    group.cn

  groupFormatSelection = (group) ->
    group.cn

  $('.ajax-ldap-groups-select').each (i, select) ->
    $(select).select2
      id: (group) ->
        group.cn
      placeholder: "Search for a LDAP group"
      minimumInputLength: 1
      query: (query) ->
        Api.ldap_groups query.term, (groups) ->
          data = { results: groups }
          query.callback(data)

      initSelection: (element, callback) ->
        id = $(element).val()
        if id isnt ""
          callback(cn: id)

      formatResult: ldapGroupResult
      formatSelection: groupFormatSelection
      dropdownCssClass: "ajax-groups-dropdown"
