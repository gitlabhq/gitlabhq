import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import '~/performance_bar/components/performance_bar_app.vue';
import performanceBar from '~/performance_bar';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

jest.mock('~/performance_bar/performance_bar_log');

describe('performance bar wrapper', () => {
  let mock;
  let vm;

  beforeEach(() => {
    setFixtures('<div id="js-peek"></div>');
    const peekWrapper = document.getElementById('js-peek');
    performance.getEntriesByType = jest.fn().mockReturnValue([]);

    peekWrapper.setAttribute('id', 'js-peek');
    peekWrapper.setAttribute('data-env', 'development');
    peekWrapper.setAttribute('data-request-id', '123');
    peekWrapper.setAttribute('data-peek-url', '/-/peek/results');
    peekWrapper.setAttribute('data-stats-url', 'https://log.gprd.gitlab.net/app/dashboards#/view/');
    peekWrapper.setAttribute('data-profile-url', '?lineprofiler=true');

    mock = new MockAdapter(axios);

    mock.onGet('/-/peek/results').reply(
      200,
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
  });

  describe('loadRequestDetails', () => {
    beforeEach(() => {
      jest.spyOn(vm.store, 'addRequest');
    });

    it('does nothing if the request cannot be tracked', () => {
      jest.spyOn(vm.store, 'canTrackRequest').mockImplementation(() => false);

      vm.loadRequestDetails('123', 'https://gitlab.com/');

      expect(vm.store.addRequest).not.toHaveBeenCalled();
    });

    it('adds the request immediately', () => {
      vm.loadRequestDetails('123', 'https://gitlab.com/');

      expect(vm.store.addRequest).toHaveBeenCalledWith('123', 'https://gitlab.com/');
    });

    it('makes an HTTP request for the request details', () => {
      jest.spyOn(PerformanceBarService, 'fetchRequestDetails');

      vm.loadRequestDetails('456', 'https://gitlab.com/');

      expect(PerformanceBarService.fetchRequestDetails).toHaveBeenCalledWith(
        '/-/peek/results',
        '456',
      );
    });
  });
});
