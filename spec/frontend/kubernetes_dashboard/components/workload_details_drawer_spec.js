import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlDrawer } from '@gitlab/ui';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import WorkloadDetailsDrawer from '~/kubernetes_dashboard/components/workload_details_drawer.vue';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import { mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const configuration = {
  basePath: 'path/to/kas/tunnel',
  baseOptions: {
    headers: { 'GitLab-Agent-Id': '1' },
  },
};

const createWrapper = () => {
  wrapper = shallowMount(WorkloadDetailsDrawer, {
    propsData: {
      configuration,
    },
  });
};

const findDrawer = () => wrapper.findComponent(GlDrawer);
const findWorkloadDetails = () => wrapper.findComponent(WorkloadDetails);

describe('Workload details drawer component', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('is closed by default', () => {
    expect(findDrawer().props('open')).toBe(false);
  });

  it("doesn't render workload details if the selected item is not provided", () => {
    expect(findWorkloadDetails().exists()).toBe(false);
  });

  describe('when receives toggle event with the item specified', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      // This method is always triggered from outside of
      // the workload_details_drawer component
      wrapper.vm.toggle(mockPodsTableItems[0]);
    });

    it('opens the drawer', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('tracks `open_kubernetes_resource_details` event', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).toHaveBeenCalledWith(
        'open_kubernetes_resource_details',
        { label: mockPodsTableItems[0].kind },
        undefined,
      );
    });

    it('provides the resource details to the drawer', () => {
      expect(findWorkloadDetails().props('item')).toEqual(mockPodsTableItems[0]);
    });

    it('provides the agent access configuration to the drawer', () => {
      expect(findWorkloadDetails().props('configuration')).toEqual(configuration);
    });

    it('renders a title with the selected item name', () => {
      expect(findDrawer().text()).toContain(mockPodsTableItems[0].name);
    });

    it('is closed when clicked on a cross button', async () => {
      expect(findDrawer().props('open')).toBe(true);

      await findDrawer().vm.$emit('close');
      expect(findDrawer().props('open')).toBe(false);
    });

    it('is closed when receives the same item for the second time', async () => {
      expect(findDrawer().props('open')).toBe(true);

      wrapper.vm.toggle(mockPodsTableItems[0]);
      await nextTick();

      expect(findDrawer().props('open')).toBe(false);
    });
  });

  describe('when receives toggle event with the item and section specified', () => {
    beforeEach(() => {
      // This method is always triggered from outside of
      // the workload_details_drawer component
      wrapper.vm.toggle(mockPodsTableItems[0], 'actions');
    });

    it('provides the resource details to the drawer', () => {
      expect(findWorkloadDetails().props('item')).toEqual(mockPodsTableItems[0]);
    });

    it('provides the selected section to the drawer', () => {
      expect(findWorkloadDetails().props('selectedSection')).toEqual('actions');
    });
  });
});
