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
        provider = $('#ldap_group_link_provider').val();
        Api.ldap_groups query.term, provider, (groups) ->
          data = { results: groups }
          query.callback(data)

      initSelection: (element, callback) ->
        id = $(element).val()
        if id isnt ""
          callback(cn: id)

      formatResult: ldapGroupResult
      formatSelection: groupFormatSelection
      dropdownCssClass: "ajax-groups-dropdown"
      formatNoMatches: (nomatch) ->
        "Match not found; try refining your search query."
  $('#ldap_group_link_provider').on 'change', ->
    $('.ajax-ldap-groups-select').select2('data', null)