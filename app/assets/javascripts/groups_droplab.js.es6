(() => {
  const global = window.gl || (window.gl = {});

  const GroupsDroplab = {
    init(trigger, list, input) {
      if (!trigger || !list) return;

      const droplab = new DropLab();

      droplab.addHook(trigger, list, [
        droplabRemoteFilter,
        droplabInfiniteScroll,
        droplabAjax,
        droplabInputSetter,
      ], {
        droplabAjax: {
          endpoint: Api.buildUrl(Api.groupsPath),
          method: 'setData',
          params: {
            per_page: 10,
            page: 1,
            skip_groups: document.querySelector('#groups-droplab').dataset.skip_groups,
          },
          deferRequest: true,
          loadingTemplate: `<i class="fa fa-spinner fa-spin"></i>`,
        },
        droplabRemoteFilter: {
          searchKey: 'search',
        },
        droplabInfiniteScroll: {
          paginationKey: 'page',
        },
        droplabInputSetter: [{
          input,
          valueAttribute: 'data-id',
        }, {
          valueAttribute: 'data-name',
        }],
      });
    }
  };

  global.GroupsDroplab = GroupsDroplab;
})();
