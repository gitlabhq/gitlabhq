import { mount, shallowMount } from '@vue/test-utils';
import { GlTable, GlBadge, GlPagination, GlDisclosureDropdown, GlButton } from '@gitlab/ui';
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
const findAllActionsDropdowns = () => wrapper.findAllComponents(GlDisclosureDropdown);
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
          expect(findRow(index).text()).toContain(data.status);
          expect(findRow(index).text()).toContain(data.age);
        });
      });

      it('renders a badge for the status', () => {
        expect(findAllBadges()).toHaveLength(mockPodsTableItems.length);
      });

      it.each`
        status         | variant      | index
        ${'Running'}   | ${'info'}    | ${0}
        ${'Running'}   | ${'info'}    | ${1}
        ${'Pending'}   | ${'warning'} | ${2}
        ${'Succeeded'} | ${'success'} | ${3}
        ${'Failed'}    | ${'danger'}  | ${4}
        ${'Failed'}    | ${'danger'}  | ${5}
      `(
        'renders "$variant" badge for status "$status" at index "$index"',
        ({ status, variant, index }) => {
          expect(findBadge(index).text()).toBe(status);
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

      it('renders pod-logs-button for each pod with containers', () => {
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

      it('renders actions column', () => {
        expect(findTable().props('fields')[lastField]).toEqual({
          key: 'actions',
          label: '',
          sortable: false,
        });
      });

      it('renders actions dropdown for each row', () => {
        expect(findAllActionsDropdowns()).toHaveLength(podItemsWithActions.length);
      });

      it('renders correct props for each dropdown', () => {
        expect(findAllActionsDropdowns().at(0).attributes('title')).toBe('Actions');
        expect(findAllActionsDropdowns().at(0).props('items')).toMatchObject([
          {
            text: 'Delete Pod',
          },
        ]);
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
