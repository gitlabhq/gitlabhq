import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import WorkloadLayout from '~/kubernetes_dashboard/components/workload_layout.vue';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import WorkloadDetailsDrawer from '~/kubernetes_dashboard/components/workload_details_drawer.vue';
import { mockPodStats, mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const defaultProps = {
  stats: mockPodStats,
  items: mockPodsTableItems,
};

const toggleDetailsDrawerSpy = jest.fn();

const createWrapper = (propsData = {}) => {
  wrapper = shallowMount(WorkloadLayout, {
    propsData: {
      ...defaultProps,
      ...propsData,
    },
    stubs: {
      WorkloadDetailsDrawer: stubComponent(WorkloadDetailsDrawer, {
        methods: { toggle: toggleDetailsDrawerSpy },
      }),
    },
  });
};

const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findErrorAlert = () => wrapper.findComponent(GlAlert);
const findWorkloadStats = () => wrapper.findComponent(WorkloadStats);
const findWorkloadTable = () => wrapper.findComponent(WorkloadTable);
const findWorkloadDetailsDrawer = () => wrapper.findComponent(WorkloadDetailsDrawer);

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

    it("doesn't render details drawer", () => {
      expect(findWorkloadDetailsDrawer().exists()).toBe(false);
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

    it("doesn't render details drawer", () => {
      expect(findWorkloadDetailsDrawer().exists()).toBe(false);
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

    it('renders workload-table component with the correct props', () => {
      expect(findWorkloadTable().props('items')).toBe(mockPodsTableItems);
    });

    it('renders details drawer', () => {
      expect(findWorkloadDetailsDrawer().exists()).toBe(true);
    });

    describe('stats', () => {
      it('renders workload-stats component with the correct props', () => {
        expect(findWorkloadStats().props('stats')).toBe(mockPodStats);
      });

      it('filters items when receives a stat select event', async () => {
        const status = 'Failed';
        findWorkloadStats().vm.$emit('select', status);
        await nextTick();

        const filteredItems = mockPodsTableItems.filter((item) => item.status === status);
        expect(findWorkloadTable().props('items')).toMatchObject(filteredItems);
      });
    });

    describe('drawer', () => {
      it('toggles the details drawer when an item was selected', async () => {
        await findWorkloadTable().vm.$emit('select-item', mockPodsTableItems[0]);

        expect(toggleDetailsDrawerSpy).toHaveBeenCalledWith(mockPodsTableItems[0]);
      });
    });
  });
});
