import AjaxCache from '~/lib/utils/ajax_cache';
import AjaxFilter from '~/droplab/plugins/ajax_filter';

describe('AjaxFilter', () => {
  let dummyConfig;
  const dummyData = 'dummy data';
  let dummyList;

  beforeEach(() => {
    dummyConfig = {
      endpoint: 'dummy endpoint',
      searchKey: 'dummy search key',
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
      jest.spyOn(AjaxCache, 'retrieve').mockImplementation(url => ajaxSpy(url));
      jest.spyOn(AjaxFilter, '_loadData').mockImplementation(() => {});

      dummyConfig.onLoadingFinished = jest.fn();

      const dynamicList = document.createElement('div');
      dynamicList.dataset.dynamic = true;
      dummyList.list.appendChild(dynamicList);
    });

    it('calls onLoadingFinished after loading data', done => {
      ajaxSpy = url => {
        expect(url).toBe('dummy endpoint?dummy search key=');
        return Promise.resolve(dummyData);
      };

      AjaxFilter.trigger()
        .then(() => {
          expect(dummyConfig.onLoadingFinished.mock.calls.length).toBe(1);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not call onLoadingFinished if Ajax call fails', done => {
      const dummyError = new Error('My dummy is sick! :-(');
      ajaxSpy = url => {
        expect(url).toBe('dummy endpoint?dummy search key=');
        return Promise.reject(dummyError);
      };

      AjaxFilter.trigger()
        .then(done.fail)
        .catch(error => {
          expect(error).toBe(dummyError);
          expect(dummyConfig.onLoadingFinished.mock.calls.length).toBe(0);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
