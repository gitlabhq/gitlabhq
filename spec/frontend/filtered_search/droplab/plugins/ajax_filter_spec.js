import AjaxFilter from '~/filtered_search/droplab/plugins/ajax_filter';
import AjaxCache from '~/lib/utils/ajax_cache';

describe('AjaxFilter', () => {
  let dummyConfig;
  const dummyData = 'dummy data';
  let dummyList;

  beforeEach(() => {
    dummyConfig = {
      endpoint: 'dummy endpoint',
      searchKey: 'dummy search key',
      searchValueFunction() {
        return 'test';
      },
    };
    dummyList = {
      data: [],
      list: document.createElement('div'),
    };

    AjaxFilter.hook = {
      config: {
        AjaxFilter: dummyConfig,
      },
      list: dummyList,
    };
  });

  describe('trigger', () => {
    let ajaxSpy;

    beforeEach(() => {
      jest.spyOn(AjaxCache, 'retrieve').mockImplementation((url) => ajaxSpy(url));
      jest.spyOn(AjaxFilter, '_loadData').mockImplementation(() => {});

      dummyConfig.onLoadingFinished = jest.fn();

      const dynamicList = document.createElement('div');
      dynamicList.dataset.dynamic = true;
      dummyList.list.appendChild(dynamicList);
    });

    it('calls onLoadingFinished after loading data', async () => {
      ajaxSpy = (url) => {
        expect(url).toBe('dummy endpoint?dummy%20search%20key=test');
        return Promise.resolve(dummyData);
      };

      await AjaxFilter.trigger();
      expect(dummyConfig.onLoadingFinished.mock.calls.length).toBe(1);
    });

    it('does not call onLoadingFinished if Ajax call fails', async () => {
      const dummyError = new Error('My dummy is sick! :-(');
      ajaxSpy = (url) => {
        expect(url).toBe('dummy endpoint?dummy%20search%20key=test');
        return Promise.reject(dummyError);
      };

      await expect(AjaxFilter.trigger()).rejects.toEqual(dummyError);
      expect(dummyConfig.onLoadingFinished.mock.calls.length).toBe(0);
    });
  });
});
