import { mount, shallowMount } from '@vue/test-utils';
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import { PAGE_SIZE } from '~/kubernetes_dashboard/constants';
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

describe('Workload table component', () => {
  it('renders GlTable component with the default fields if no fields specified in props', () => {
    createWrapper({ items: mockPodsTableItems });
    const defaultFields = [
      {
        key: 'name',
        label: 'Name',
        sortable: true,
        tdClass: 'gl-md-w-half gl-lg-w-40p gl-word-break-word',
      },
      {
        key: 'status',
        label: 'Status',
        sortable: true,
        tdClass: 'gl-md-w-15',
      },
      {
        key: 'namespace',
        label: 'Namespace',
        sortable: true,
        tdClass: 'gl-md-w-30p gl-lg-w-40p gl-word-break-word',
      },
      {
        key: 'age',
        label: 'Age',
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

  describe('row selection', () => {
    beforeEach(() => {
      createWrapper({ items: mockPodsTableItems });
    });

    it('emits row-selected event on row click', () => {
      mockPodsTableItems.forEach((data, index) => {
        findTable().vm.$emit('row-selected', [data]);

        expect(wrapper.emitted('select-item')[index]).toEqual([data]);
      });
    });

    it('emits remove-selection event on the second click on the same item', () => {
      findTable().vm.$emit('row-selected', [mockPodsTableItems[0]]);
      expect(wrapper.emitted('select-item')).toEqual([[mockPodsTableItems[0]]]);

      findTable().vm.$emit('row-selected', mockPodsTableItems[0]);
      expect(wrapper.emitted('remove-selection')).toHaveLength(1);
    });
  });
});
