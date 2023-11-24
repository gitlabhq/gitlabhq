import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import WorkloadLayout from '~/kubernetes_dashboard/components/workload_layout.vue';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import { mockPodStats, mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const defaultProps = {
  stats: mockPodStats,
  items: mockPodsTableItems,
};

const createWrapper = (propsData = {}) => {
  wrapper = shallowMount(WorkloadLayout, {
    propsData: {
      ...defaultProps,
      ...propsData,
    },
  });
};

const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findErrorAlert = () => wrapper.findComponent(GlAlert);
const findWorkloadStats = () => wrapper.findComponent(WorkloadStats);
const findWorkloadTable = () => wrapper.findComponent(WorkloadTable);

describe('Workload layout component', () => {
  describe('when loading', () => {
    beforeEach(() => {
      createWrapper({ loading: true, errorMessage: 'error' });
    });

    it('renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it("doesn't render an error message", () => {
      expect(findErrorAlert().exists()).toBe(false);
    });

    it("doesn't render workload stats", () => {
      expect(findWorkloadStats().exists()).toBe(false);
    });

    it("doesn't render workload table", () => {
      expect(findWorkloadTable().exists()).toBe(false);
    });
  });

  describe('when received an error', () => {
    beforeEach(() => {
      createWrapper({ errorMessage: 'error' });
    });

    it("doesn't render a loading icon", () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders an error alert with the correct message and props', () => {
      expect(findErrorAlert().text()).toBe('error');
      expect(findErrorAlert().props()).toMatchObject({ variant: 'danger', dismissible: false });
    });

    it("doesn't render workload stats", () => {
      expect(findWorkloadStats().exists()).toBe(false);
    });

    it("doesn't render workload table", () => {
      expect(findWorkloadTable().exists()).toBe(false);
    });
  });

  describe('when received the data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it("doesn't render a loading icon", () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it("doesn't render an error message", () => {
      expect(findErrorAlert().exists()).toBe(false);
    });

    it('renders workload-stats component with the correct props', () => {
      expect(findWorkloadStats().props('stats')).toBe(mockPodStats);
    });

    it('renders workload-table component with the correct props', () => {
      expect(findWorkloadTable().props('items')).toBe(mockPodsTableItems);
    });
  });
});
