import { GlFormCheckbox } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTableCell from '~/work_items/table/components/work_item_table_cell.vue';
import WorkItemTableRow from '~/work_items/table/components/work_item_table_row.vue';
import WorkItemTitleCell from '~/work_items/table/components/work_item_title_cell.vue';
import {
  COLUMN_ASSIGNEES,
  COLUMN_REFERENCE,
  COLUMN_TITLE,
  TABLE_COLUMNS,
} from '~/work_items/table/constants';
import { buildAssigneesWidget, buildWorkItemNode, mockAssignees } from '../../board/mock_data';

describe('WorkItemTableRow', () => {
  let wrapper;

  const item = buildWorkItemNode(1, { title: 'Some work item' });
  const columns = TABLE_COLUMNS.filter(({ key }) => [COLUMN_TITLE, COLUMN_REFERENCE].includes(key));

  const findTitleCell = () => wrapper.findComponent(WorkItemTitleCell);
  const findCells = () => wrapper.findAllComponents(WorkItemTableCell);

  const findRow = () => wrapper.findByTestId('work-item-table-row');
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findCheckboxCell = () => wrapper.findByTestId('work-item-table-checkbox-cell');

  const createComponent = ({ mountFn = shallowMountExtended, props = {} } = {}) => {
    wrapper = mountFn(WorkItemTableRow, {
      propsData: { item, columns, rootPageFullPath: 'group', ...props },
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

  describe('when the detail panel is enabled', () => {
    beforeEach(() => {
      createComponent({ props: { detailPanelEnabled: true } });
    });

    it('asks for the work item to be opened in the panel', async () => {
      await findRow().trigger('click');

      expect(wrapper.emitted('set-active-item')).toEqual([[item]]);
    });

    it.each(['metaKey', 'ctrlKey', 'shiftKey'])(
      'leaves a %s click to the browser, so the link opens in a new tab',
      async (modifier) => {
        await findRow().trigger('click', { [modifier]: true });

        expect(wrapper.emitted('set-active-item')).toBeUndefined();
      },
    );

    it('leaves clicks on the other links in a row to those links', async () => {
      // The assignee name links to a profile, and the row must not hijack it. The avatar
      // next to it is no substitute here: UserAvatarLink stops the click itself, so it
      // never reaches the row and the guard under test never runs.
      wrapper = mountExtended(WorkItemTableRow, {
        attachTo: document.body,
        propsData: {
          item: buildWorkItemNode(1, { widgets: [buildAssigneesWidget([mockAssignees[0]])] }),
          columns: TABLE_COLUMNS.filter(({ key }) => key === COLUMN_ASSIGNEES),
          rootPageFullPath: 'group',
          detailPanelEnabled: true,
        },
      });

      // Records what the row left the event at, then stops jsdom following the href. It
      // follows it on a timer that lands after this test has finished, where the
      // unsupported navigation is logged against whichever spec is running by then.
      let preventedByRow;
      document.addEventListener(
        'click',
        (event) => {
          preventedByRow = event.defaultPrevented;
          event.preventDefault();
        },
        { once: true },
      );

      await wrapper.findByTestId('assignee-name-link').trigger('click');

      expect(preventedByRow).toBe(false);
      expect(wrapper.emitted('set-active-item')).toBeUndefined();
    });

    it('opens the panel from the title link rather than following it', async () => {
      createComponent({ mountFn: mountExtended, props: { detailPanelEnabled: true } });

      await wrapper.findByTestId('work-item-link').trigger('click');

      expect(wrapper.emitted('set-active-item')).toEqual([[item]]);
    });

    describe('and the work item is the one already open', () => {
      beforeEach(() => {
        createComponent({ props: { detailPanelEnabled: true, activeItem: item } });
      });

      it('marks the row as the current one', () => {
        expect(findRow().attributes('aria-current')).toBe('true');
        expect(findRow().classes()).toContain('!gl-bg-feedback-info');
      });

      it('closes the panel when the row is clicked again', async () => {
        await findRow().trigger('click');

        expect(wrapper.emitted('set-active-item')).toEqual([[null]]);
      });
    });
  });

  describe('when the detail panel is disabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('leaves the row click to the title link', async () => {
      await findRow().trigger('click');

      expect(wrapper.emitted('set-active-item')).toBeUndefined();
      expect(findRow().classes()).not.toContain('gl-cursor-pointer');
    });
  });

  describe('bulk edit checkbox', () => {
    it('is absent by default', () => {
      createComponent({ mountFn: mountExtended });

      expect(findCheckboxCell().exists()).toBe(false);
      expect(wrapper.findAll('td')).toHaveLength(1);
    });

    describe('when the row can be selected', () => {
      beforeEach(() => {
        createComponent({ mountFn: mountExtended, props: { showCheckbox: true } });
      });

      it('renders an unchecked checkbox named after the work item', () => {
        expect(findCheckbox().props('checked')).toBe(false);
        expect(findCheckboxCell().text()).toBe(item.title);
      });

      it('reports the new state when checked', async () => {
        // A synthetic click ticks the box without firing `change`, which is the event the
        // checkbox actually listens to, so this toggles it the way a real one would.
        const checkbox = wrapper.find('input[type="checkbox"]');
        checkbox.element.checked = true;
        await checkbox.trigger('change');

        expect(wrapper.emitted('checked-input')).toEqual([[true]]);
      });
    });

    describe('while the side panel is enabled', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          props: { showCheckbox: true, detailPanelEnabled: true },
        });
      });

      it('does not open the work item when the checkbox cell is clicked', () => {
        findCheckboxCell().trigger('click');

        expect(wrapper.emitted('set-active-item')).toBeUndefined();
      });

      it('does not open the work item when the row is clicked', async () => {
        await findRow().trigger('click');

        expect(wrapper.emitted('set-active-item')).toBeUndefined();
        expect(findRow().classes()).not.toContain('gl-cursor-pointer');
      });
    });

    it('renders a checked checkbox when the row is selected', () => {
      createComponent({ mountFn: mountExtended, props: { showCheckbox: true, checked: true } });

      expect(findCheckbox().props('checked')).toBe(true);
    });
  });
});
