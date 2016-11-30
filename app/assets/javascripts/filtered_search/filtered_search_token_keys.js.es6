/* eslint-disable no-param-reassign */
((global) => {
  class FilteredSearchTokenKeys {
    static get() {
      return [{
        key: 'author',
        type: 'string',
        param: 'username',
        symbol: '@',
      }, {
        key: 'assignee',
        type: 'string',
        param: 'username',
        symbol: '@',
        conditions: [{
          keyword: 'none',
          url: 'assignee_id=0',
        }],
      }, {
        key: 'milestone',
        type: 'string',
        param: 'title',
        symbol: '%',
        conditions: [{
          keyword: 'none',
          url: 'milestone_title=No+Milestone',
        }, {
          keyword: 'upcoming',
          url: 'milestone_title=%23upcoming',
        }],
      }, {
        key: 'label',
        type: 'array',
        param: 'name[]',
        symbol: '~',
        conditions: [{
          keyword: 'none',
          url: 'label_name[]=No+Label',
        }],
      }];
    }
  }

  global.FilteredSearchTokenKeys = FilteredSearchTokenKeys;
})(window.gl || (window.gl = {}));
