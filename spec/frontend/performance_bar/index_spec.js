import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import '~/performance_bar/components/performance_bar_app.vue';
import performanceBar from '~/performance_bar';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

Vue.config.ignoredElements = ['gl-emoji'];

jest.mock('~/performance_bar/performance_bar_log');

describe('performance bar wrapper', () => {
  let mock;
  let vm;

  beforeEach(() => {
    setHTMLFixture('<div id="js-peek"></div>');
    const peekWrapper = document.getElementById('js-peek');
    performance.getEntriesByType = jest.fn().mockReturnValue([]);

    peekWrapper.setAttribute('id', 'js-peek');
    peekWrapper.dataset.env = 'development';
    peekWrapper.dataset.requestId = '123';
    peekWrapper.dataset.requestMethod = 'GET';
    peekWrapper.dataset.peekUrl = '/-/peek/results';
    peekWrapper.dataset.statsUrl = 'https://log.gprd.gitlab.net/app/dashboards#/view/';

    mock = new MockAdapter(axios);

    mock.onGet('/-/peek/results').reply(
      HTTP_STATUS_OK,
      {
        data: {
          gc: {
            invokes: 0,
            invoke_time: '0.00',
            use_size: 0,
            total_size: 0,
            total_object: 0,
            gc_time: '0.00',
          },
          host: { hostname: 'web-01' },
        },
      },
      {},
    );

    vm = performanceBar(peekWrapper);
  });

  afterEach(() => {
    vm.$destroy();
    document.getElementById('js-peek').remove();
    mock.restore();
    resetHTMLFixture();
  });

  describe('addRequest', () => {
    beforeEach(() => {
      jest.spyOn(vm.store, 'addRequest');
    });

    it('does nothing if the request cannot be tracked', () => {
      jest.spyOn(vm.store, 'canTrackRequest').mockImplementation(() => false);

      vm.addRequest('123', 'https://gitlab.com/');

      expect(vm.store.addRequest).not.toHaveBeenCalled();
    });

    it('adds the request immediately', () => {
      vm.addRequest('123', 'https://gitlab.com/');

      expect(vm.store.addRequest).toHaveBeenCalledWith(
        '123',
        'https://gitlab.com/',
        undefined,
        undefined,
        undefined,
      );
    });
  });

  describe('loadRequestDetails', () => {
    beforeEach(() => {
      jest.spyOn(PerformanceBarService, 'fetchRequestDetails');
    });

    it('makes an HTTP request for the request details', () => {
      vm.addRequest('456', 'https://gitlab.com/');
      vm.loadRequestDetails('456');

      expect(PerformanceBarService.fetchRequestDetails).toHaveBeenCalledWith(
        '/-/peek/results',
        '456',
      );
    });

    it('does not make a request if request was not added', () => {
      vm.loadRequestDetails('456');

      expect(PerformanceBarService.fetchRequestDetails).not.toHaveBeenCalled();
    });

    it('makes an HTTP request only once for the same request', async () => {
      vm.addRequest('456', 'https://gitlab.com/');
      await vm.loadRequestDetails('456');

      vm.loadRequestDetails('456');

      expect(PerformanceBarService.fetchRequestDetails).toHaveBeenCalledTimes(1);
    });
  });
});
