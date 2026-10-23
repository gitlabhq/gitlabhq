import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue from 'vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import StatisticsPanelApp from '~/admin/statistics_panel/components/app.vue';
import statisticsLabels from '~/admin/statistics_panel/constants';
import { useAdminStatistics } from '~/admin/statistics_panel/store';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import mockStatistics from '../mock_data';

Vue.use(PiniaVuePlugin);

describe('Admin statistics app', () => {
  let wrapper;
  let pinia;
  let store;

  const createComponent = () => {
    wrapper = shallowMount(StatisticsPanelApp, {
      pinia,
      stubs: {
        CrudComponent,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia();
    store = useAdminStatistics();
  });

  const findStats = (idx) => wrapper.findAll('.js-stats').at(idx);

  describe('on mount', () => {
    it('fetches the statistics', () => {
      createComponent();

      expect(store.fetchStatistics).toHaveBeenCalledTimes(1);
    });
  });

  describe('template', () => {
    describe('when app is loading', () => {
      it('renders a skeleton loader', () => {
        store.isLoading = true;
        createComponent();

        expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
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
        store.statistics = statistics;
        createComponent();

        expect(findStats(index).text()).toContain(label);
        expect(findStats(index).text()).toContain(count.toString());
      });
    });
  });
});
