import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import StatisticsPanelApp from '~/admin/statistics_panel/components/app.vue';
import statisticsLabels from '~/admin/statistics_panel/constants';
import createStore from '~/admin/statistics_panel/store';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import mockStatistics from '../mock_data';

Vue.use(Vuex);

describe('Admin statistics app', () => {
  let wrapper;
  let store;
  let axiosMock;

  const createComponent = () => {
    wrapper = shallowMount(StatisticsPanelApp, {
      store,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(/api\/(.*)\/application\/statistics/).reply(HTTP_STATUS_OK);
    store = createStore();
  });

  const findStats = (idx) => wrapper.findAll('.js-stats').at(idx);

  describe('template', () => {
    describe('when app is loading', () => {
      it('renders a loading indicator', () => {
        store.dispatch('requestStatistics');
        createComponent();

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    });

    describe('when app has finished loading', () => {
      const statistics = convertObjectPropsToCamelCase(mockStatistics, { deep: true });

      it.each`
        statistic          | count  | index
        ${'forks'}         | ${12}  | ${0}
        ${'issues'}        | ${180} | ${1}
        ${'mergeRequests'} | ${31}  | ${2}
        ${'notes'}         | ${986} | ${3}
        ${'snippets'}      | ${50}  | ${4}
        ${'sshKeys'}       | ${10}  | ${5}
        ${'milestones'}    | ${40}  | ${6}
        ${'activeUsers'}   | ${50}  | ${7}
      `('renders the count for the $statistic statistic', ({ statistic, count, index }) => {
        const label = statisticsLabels[statistic];
        store.dispatch('receiveStatisticsSuccess', statistics);
        createComponent();

        expect(findStats(index).text()).toContain(label);
        expect(findStats(index).text()).toContain(count.toString());
      });
    });
  });
});
