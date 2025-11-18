import { mount, shallowMount } from '@vue/test-utils';
import { GlTable, GlBadge, GlPagination, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import { stubComponent } from 'helpers/stub_component';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import {
  PAGE_SIZE,
  DEFAULT_WORKLOAD_TABLE_FIELDS,
  PODS_TABLE_FIELDS,
} from '~/kubernetes_dashboard/constants';
import PodLogsButton from '~/environments/environment_details/components/kubernetes/pod_logs_button.vue';
import { mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const tableProps = ['perPage', 'currentPage', 'hover', 'selectable', 'noSelectOnClick'];

const createWrapper = (propsData = {}, shallow = false) => {
  const mountFn = shallow ? shallowMount : mount;
  wrapper = mountFn(WorkloadTable, {
    propsData,
    stubs: shallow
      ? {
          GlTable: stubComponent(GlTable, { props: tableProps }),
        }
      : {},
  });
};

const findTable = () => wrapper.findComponent(GlTable);
const findAllRows = () => findTable().find('tbody').findAll('tr');
const findRow = (at) => findAllRows().at(at);
const findAllBadges = () => wrapper.findAllComponents(GlBadge);
const findBadge = (at) => findAllBadges().at(at);
const findPagination = () => wrapper.findComponent(GlPagination);
const findAllPodLogsButtons = () => wrapper.findAllComponents(PodLogsButton);
const findAllActionButtons = () => wrapper.findAll('[data-testid="delete-action-button"]');
const findAllPodNameButtons = () => wrapper.findAllComponents(GlButton);

describe('Workload table component', () => {
  it('renders GlTable component with the default fields if no fields specified in props', () => {
    createWrapper({ items: mockPodsTableItems });

    expect(findTable().props('fields')).toMatchObject(DEFAULT_WORKLOAD_TABLE_FIELDS);
  });

  it('renders GlTable component fields specified in props', () => {
    const customFields = [
      {
        key: 'field-1',
        label: 'Field-1',
        sortable: true,
      },
      {
        key: 'field-2',
        label: 'Field-2',
        sortable: true,
      },
    ];
    createWrapper({ items: mockPodsTableItems, fields: customFields });

    expect(findTable().props('fields')).toEqual(customFields);
  });

  describe('table rows', () => {
    describe('with default fields', () => {
      beforeEach(() => {
        createWrapper({ items: mockPodsTableItems });
      });

      it('displays the correct number of rows', () => {
        expect(findAllRows()).toHaveLength(mockPodsTableItems.length);
      });

      it('renders correct data for each row', () => {
        mockPodsTableItems.forEach((data, index) => {
          expect(findRow(index).text()).toContain(data.name);
          expect(findRow(index).text()).toContain(data.namespace);
          expect(findRow(index).text()).toContain(data.statusText || data.status);
          expect(findRow(index).text()).toContain(data.age);
        });
      });

      it('renders a badge for the status', () => {
        expect(findAllBadges()).toHaveLength(mockPodsTableItems.length);
      });

      it.each`
        status         | statusText | variant      | index
        ${'Running'}   | ${''}      | ${'info'}    | ${0}
        ${'Running'}   | ${''}      | ${'info'}    | ${1}
        ${'Pending'}   | ${''}      | ${'warning'} | ${2}
        ${'Succeeded'} | ${''}      | ${'success'} | ${3}
        ${'Failed'}    | ${'Error'} | ${'danger'}  | ${4}
        ${'Failed'}    | ${''}      | ${'danger'}  | ${5}
      `(
        'renders "$variant" badge for status "$status" at index "$index"',
        ({ status, statusText, variant, index }) => {
          expect(findBadge(index).text()).toBe(statusText || status);
          expect(findBadge(index).props('variant')).toBe(variant);
        },
      );
    });

    describe('with containers field specified', () => {
      const containers = [{ name: 'my-container-1' }, { name: 'my-container-2' }];
      const itemsWithContainers = cloneDeep(mockPodsTableItems);
      itemsWithContainers[0].containers = containers;

      beforeEach(() => {
        createWrapper({ items: itemsWithContainers, fields: PODS_TABLE_FIELDS });
      });

      it('renders pod-logs-button in actions column for each pod with containers', () => {
        expect(findAllPodLogsButtons()).toHaveLength(1);
      });

      it('renders correct data for each button', () => {
        const pod = itemsWithContainers[0];
        expect(findAllPodLogsButtons().at(0).props()).toEqual({
          podName: pod.name,
          namespace: pod.namespace,
          containers,
        });
      });
    });

    describe('with actions field specified', () => {
      const actions = [
        {
          name: 'delete-pod',
          text: 'Delete Pod',
          class: 'text-danger',
        },
      ];
      const podItemsWithActions = mockPodsTableItems.map((item) => {
        return {
          ...item,
          actions,
        };
      });
      const lastField = PODS_TABLE_FIELDS.length - 1;

      beforeEach(() => {
        createWrapper({ items: podItemsWithActions, fields: PODS_TABLE_FIELDS });
      });

      it('renders actions column with proper label', () => {
        expect(findTable().props('fields')[lastField]).toEqual({
          key: 'actions',
          label: 'Actions',
          sortable: false,
        });
      });

      it('renders delete button for items with delete-pod action', () => {
        expect(findAllActionButtons()).toHaveLength(podItemsWithActions.length);
      });

      it('renders delete button with correct props', () => {
        expect(findAllActionButtons().at(0).props()).toMatchObject({
          icon: 'remove',
          size: 'small',
          variant: 'danger',
          category: 'tertiary',
        });
      });

      it('emits delete-pod event when delete button is clicked', async () => {
        await findAllActionButtons().at(0).trigger('click');

        expect(wrapper.emitted('delete-pod')).toHaveLength(1);
        expect(wrapper.emitted('delete-pod')[0]).toEqual([podItemsWithActions[0]]);
      });
    });
  });

  describe('pagination', () => {
    describe('when page size is not provided in props', () => {
      it('renders pagination with the default page size', () => {
        createWrapper({ items: mockPodsTableItems });

        expect(findPagination().props('perPage')).toBe(PAGE_SIZE);
      });

      it('shows the default number of items in the table', () => {
        createWrapper({ items: mockPodsTableItems }, true);

        expect(findTable().props('perPage')).toBe(PAGE_SIZE);
      });
    });

    describe('when page size is provided in props', () => {
      it('renders pagination with the specified page size', () => {
        createWrapper({ items: mockPodsTableItems, pageSize: 5 });

        expect(findPagination().props('perPage')).toBe(5);
      });

      it('shows the specified number of items in the table', () => {
        createWrapper({ items: mockPodsTableItems, pageSize: 5 }, true);

        expect(findTable().props('perPage')).toBe(5);
      });
    });

    it('updates the table with the current page', async () => {
      createWrapper({ items: mockPodsTableItems }, true);

      expect(findTable().props('currentPage')).toBe(1);

      findPagination().vm.$emit('input', 2);
      await nextTick();

      expect(findTable().props('currentPage')).toBe(2);
    });

    describe('pagination behavior on items change', () => {
      const largeDataset = Array.from({ length: 25 }, (_, i) => ({
        ...mockPodsTableItems[0],
        name: `pod-${i}`,
      }));

      beforeEach(() => {
        createWrapper({ items: largeDataset, pageSize: 10 }, true);
      });

      it('preserves current page when items are updated but page is still valid', async () => {
        findPagination().vm.$emit('input', 2);
        await nextTick();

        expect(findTable().props('currentPage')).toBe(2);

        const updatedItems = largeDataset.map((item) => ({ ...item, status: 'Running' }));
        await wrapper.setProps({ items: updatedItems });

        expect(findTable().props('currentPage')).toBe(2);
      });

      it('navigates to last page when current page becomes invalid due to fewer items', async () => {
        findPagination().vm.$emit('input', 3);
        await nextTick();
        expect(findTable().props('currentPage')).toBe(3);

        const reducedItems = largeDataset.slice(0, 15);
        await wrapper.setProps({ items: reducedItems });

        expect(findTable().props('currentPage')).toBe(2);
      });

      it('navigates to page 1 when all items are significantly reduced', async () => {
        findPagination().vm.$emit('input', 3);
        await nextTick();
        expect(findTable().props('currentPage')).toBe(3);

        const reducedItems = largeDataset.slice(0, 5);
        await wrapper.setProps({ items: reducedItems });

        expect(findTable().props('currentPage')).toBe(1);
      });

      it('preserves current page when items are added', async () => {
        findPagination().vm.$emit('input', 2);
        await nextTick();
        expect(findTable().props('currentPage')).toBe(2);

        const expandedItems = [
          ...largeDataset,
          ...Array.from({ length: 10 }, (_, i) => ({
            ...mockPodsTableItems[0],
            name: `new-pod-${i}`,
          })),
        ];
        await wrapper.setProps({ items: expandedItems });

        expect(findTable().props('currentPage')).toBe(2);
      });
    });

    describe('resetPagination method', () => {
      it('resets current page to 1 when called', async () => {
        const largeDataset = Array.from({ length: 25 }, (_, i) => ({
          ...mockPodsTableItems[0],
          name: `pod-${i}`,
        }));

        createWrapper({ items: largeDataset, pageSize: 10 }, true);

        findPagination().vm.$emit('input', 2);
        await nextTick();
        expect(findTable().props('currentPage')).toBe(2);

        // Note: This method can only be triggered from outside of the component
        wrapper.vm.resetPagination();
        await nextTick();

        expect(findTable().props('currentPage')).toBe(1);
      });
    });
  });

  describe('item selection', () => {
    beforeEach(() => {
      createWrapper({ items: mockPodsTableItems });
    });

    it('emits "select-item" event on the pod name click', () => {
      const podNameButtons = findAllPodNameButtons();

      mockPodsTableItems.forEach((data, index) => {
        podNameButtons.at(index).vm.$emit('click', data);

        expect(wrapper.emitted('select-item')[index]).toEqual([data]);
      });
    });
  });
});
