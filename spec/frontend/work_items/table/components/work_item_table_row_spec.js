import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTableCell from '~/work_items/table/components/work_item_table_cell.vue';
import WorkItemTableRow from '~/work_items/table/components/work_item_table_row.vue';
import WorkItemTitleCell from '~/work_items/table/components/work_item_title_cell.vue';
import { COLUMN_REFERENCE, COLUMN_TITLE, TABLE_COLUMNS } from '~/work_items/table/constants';
import { buildWorkItemNode } from '../../board/mock_data';

describe('WorkItemTableRow', () => {
  let wrapper;

  const item = buildWorkItemNode(1, { title: 'Some work item' });
  const columns = TABLE_COLUMNS.filter(({ key }) => [COLUMN_TITLE, COLUMN_REFERENCE].includes(key));

  const findTitleCell = () => wrapper.findComponent(WorkItemTitleCell);
  const findCells = () => wrapper.findAllComponents(WorkItemTableCell);

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(WorkItemTableRow, {
      propsData: { item, columns, rootPageFullPath: 'group' },
    });
  };

  describe('cells', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('renders the title as the row header', () => {
      expect(wrapper.find('th').attributes('scope')).toBe('row');
    });

    it('renders a data cell for each of the other columns', () => {
      expect(wrapper.findAll('td')).toHaveLength(1);
      expect(findCells()).toHaveLength(1);
      expect(findCells().at(0).props('columnKey')).toBe(COLUMN_REFERENCE);
    });
  });

  describe('title', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title cell with the work item', () => {
      expect(findTitleCell().props('item')).toBe(item);
    });
  });
});
