import { GlAlert } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import ProjectsAndGroupChart from '~/analytics/usage_trends/components/projects_and_groups_chart.vue';
import groupsQuery from '~/analytics/usage_trends/graphql/queries/groups.query.graphql';
import projectsQuery from '~/analytics/usage_trends/graphql/queries/projects.query.graphql';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { mockQueryResponse } from '../apollo_mock_data';
import { mockCountsData2, roundedSortedCountsMonthlyChartData2 } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('ProjectsAndGroupChart', () => {
  let wrapper;
  let queryResponses = { projects: null, groups: null };
  const mockAdditionalData = [{ recordedAt: '2020-07-21', count: 5 }];

  const createComponent = ({
    loadingError = false,
    projects = [],
    groups = [],
    projectsLoading = false,
    groupsLoading = false,
    projectsAdditionalData = [],
    groupsAdditionalData = [],
  } = {}) => {
    queryResponses = {
      projects: mockQueryResponse({
        key: 'projects',
        data: projects,
        loading: projectsLoading,
        additionalData: projectsAdditionalData,
      }),
      groups: mockQueryResponse({
        key: 'groups',
        data: groups,
        loading: groupsLoading,
        additionalData: groupsAdditionalData,
      }),
    };

    return shallowMount(ProjectsAndGroupChart, {
      props: {
        startDate: new Date(2020, 9, 26),
        endDate: new Date(2020, 10, 1),
        totalDataPoints: mockCountsData2.length,
      },
      localVue,
      apolloProvider: createMockApollo([
        [projectsQuery, queryResponses.projects],
        [groupsQuery, queryResponses.groups],
      ]),
      data() {
        return { loadingError };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    queryResponses = {
      projects: null,
      groups: null,
    };
  });

  const findLoader = () => wrapper.find(ChartSkeletonLoader);
  const findAlert = () => wrapper.find(GlAlert);
  const findChart = () => wrapper.find(GlLineChart);

  describe('while loading', () => {
    beforeEach(() => {
      wrapper = createComponent({ projectsLoading: true, groupsLoading: true });
    });

    it('displays the skeleton loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('hides the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('while loading 1 data set', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        projects: mockCountsData2,
        groupsLoading: true,
      });

      await wrapper.vm.$nextTick();
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });
  });

  describe('without data', () => {
    beforeEach(async () => {
      wrapper = createComponent({ projects: [] });
      await wrapper.vm.$nextTick();
    });

    it('renders a no data message', () => {
      expect(findAlert().text()).toBe('No data available.');
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not render the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      wrapper = createComponent({ projects: mockCountsData2 });
      await wrapper.vm.$nextTick();
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('passes the data to the line chart', () => {
      expect(findChart().props('data')).toEqual([
        { data: roundedSortedCountsMonthlyChartData2, name: 'Total projects' },
        { data: [], name: 'Total groups' },
      ]);
    });
  });

  describe('with errors', () => {
    beforeEach(async () => {
      wrapper = createComponent({ loadingError: true });
      await wrapper.vm.$nextTick();
    });

    it('renders an error message', () => {
      expect(findAlert().text()).toBe('No data available.');
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('hides the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe.each`
    metric        | loadingState                                      | newData
    ${'projects'} | ${{ projectsAdditionalData: mockAdditionalData }} | ${{ projects: mockCountsData2 }}
    ${'groups'}   | ${{ groupsAdditionalData: mockAdditionalData }}   | ${{ groups: mockCountsData2 }}
  `('$metric - fetchMore', ({ metric, loadingState, newData }) => {
    describe('when the fetchMore query returns data', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          ...loadingState,
          ...newData,
        });

        jest.spyOn(wrapper.vm.$apollo.queries[metric], 'fetchMore');
        await wrapper.vm.$nextTick();
      });

      it('requests data twice', () => {
        expect(queryResponses[metric]).toBeCalledTimes(2);
      });

      it('calls fetchMore', () => {
        expect(wrapper.vm.$apollo.queries[metric].fetchMore).toHaveBeenCalledTimes(1);
      });
    });

    describe('when the fetchMore query throws an error', () => {
      beforeEach(() => {
        wrapper = createComponent({
          ...loadingState,
          ...newData,
        });

        jest
          .spyOn(wrapper.vm.$apollo.queries[metric], 'fetchMore')
          .mockImplementation(jest.fn().mockRejectedValue());
        return wrapper.vm.$nextTick();
      });

      it('calls fetchMore', () => {
        expect(wrapper.vm.$apollo.queries[metric].fetchMore).toHaveBeenCalledTimes(1);
      });

      it('renders an error message', () => {
        expect(findAlert().text()).toBe('No data available.');
      });
    });
  });
});
