/* eslint-disable func-names, space-before-function-paren, object-shorthand, quotes, no-var, one-var, one-var-declaration-per-line, prefer-arrow-callback, consistent-return, no-unused-vars, camelcase, prefer-template, comma-dangle, max-len */

(function() {
  window.GroupsList = {
    init: function() {
      $(".groups-list-filter").off('keyup');
      this.initSearch();
      return this.initPagination();
    },
    initSearch: function() {
      var debounceFilter, groupsListFilter;
      groupsListFilter = $('.groups-list-filter');
      debounceFilter = _.debounce(window.GroupsList.filterResults, 500);
      return groupsListFilter.on('keyup', function(e) {
        if (groupsListFilter.val() !== '') {
          return debounceFilter();
        }
      });
    },
    filterResults: function() {
      var form, group_filter_url, search;
      $('.groups-list-holder').fadeTo(250, 0.5);
      form = null;
      form = $("form#group-filter-form");
      search = $(".groups-list-filter").val();
      group_filter_url = form.attr('action') + '?' + form.serialize();
      return $.ajax({
        type: "GET",
        url: form.attr('action'),
        data: form.serialize(),
        complete: function() {
          return $('.groups-list-holder').fadeTo(250, 1);
        },
        success: function(data) {
          $('.groups-list-holder').replaceWith(data.html);
          return history.replaceState({
            page: group_filter_url
          // Change url so if user reload a page - search results are saved
          }, document.title, group_filter_url);
        },
        dataType: "json"
      });
    },
    initPagination: function() {
      return $('.groups-list-holder .pagination').on('ajax:success', function(e, data) {
        return $('.groups-list-holder').replaceWith(data.html);
      });
    }
  };
}).call(window);
