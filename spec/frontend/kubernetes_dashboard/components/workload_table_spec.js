import { mount } from '@vue/test-utils';
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import { TABLE_HEADING_CLASSES, PAGE_SIZE } from '~/kubernetes_dashboard/constants';
import { mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const createWrapper = (propsData = {}) => {
  wrapper = mount(WorkloadTable, {
    propsData,
  });
};

const findTable = () => wrapper.findComponent(GlTable);
const findAllRows = () => findTable().find('tbody').findAll('tr');
const findRow = (at) => findAllRows().at(at);
const findAllBadges = () => wrapper.findAllComponents(GlBadge);
const findBadge = (at) => findAllBadges().at(at);
const findPagination = () => wrapper.findComponent(GlPagination);

describe('Workload table component', () => {
  it('renders GlTable component with the default fields if no fields specified in props', () => {
    createWrapper({ items: mockPodsTableItems });
    const defaultFields = [
      {
        key: 'name',
        label: 'Name',
        thClass: TABLE_HEADING_CLASSES,
        sortable: true,
      },
      {
        key: 'status',
        label: 'Status',
        thClass: TABLE_HEADING_CLASSES,
        sortable: true,
      },
      {
        key: 'namespace',
        label: 'Namespace',
        thClass: TABLE_HEADING_CLASSES,
        sortable: true,
      },
      {
        key: 'age',
        label: 'Age',
        thClass: TABLE_HEADING_CLASSES,
        sortable: true,
      },
    ];

    expect(findTable().props('fields')).toEqual(defaultFields);
  });

  it('renders GlTable component fields specified in props', () => {
    const customFields = [
      {
        key: 'field-1',
        label: 'Field-1',
        thClass: TABLE_HEADING_CLASSES,
        sortable: true,
      },
      {
        key: 'field-2',
        label: 'Field-2',
        thClass: TABLE_HEADING_CLASSES,
        sortable: true,
      },
    ];
    createWrapper({ items: mockPodsTableItems, fields: customFields });

    expect(findTable().props('fields')).toEqual(customFields);
  });

  describe('table rows', () => {
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

    it('renders pagination', () => {
      expect(findPagination().props()).toMatchObject({
        totalItems: mockPodsTableItems.length,
        perPage: PAGE_SIZE,
      });
    });
  });
});
