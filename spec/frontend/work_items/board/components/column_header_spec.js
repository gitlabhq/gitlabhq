import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColumnHeader from '~/work_items/board/components/column_header.vue';
import { getAdaptiveStatusColor } from '~/lib/utils/color_utils';
import { mockStatus } from '../mock_data';

jest.mock('~/lib/utils/color_utils', () => ({
  getAdaptiveStatusColor: jest.fn(() => '#89888d'),
}));

describe('ColumnHeader', () => {
  let wrapper;

  const findIcons = () => wrapper.findAllComponents(GlIcon);
  const findIconByName = (name) => findIcons().wrappers.find((icon) => icon.props('name') === name);
  const findHeading = () => wrapper.findByTestId('column-header-name');
  const findCount = () => wrapper.findByTestId('column-header-count');
  const findCollapseToggle = () => wrapper.findComponentByTestId('column-collapse-toggle');
  const findHeaderBar = () => wrapper.findByTestId('column-header');
  const findActionsMenu = () => wrapper.findComponentByTestId('column-actions-menu');
  const findActionItem = (index) => findActionsMenu().props('items')[index];
  const DRAG_HANDLE_CLASS = 'js-board-column-drag-handle';
  const findCreateButton = () => wrapper.findComponentByTestId('column-create-item');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ColumnHeader, {
      propsData: {
        value: mockStatus,
        decoration: { type: 'icon', name: 'status-waiting', color: '#737278' },
        count: 5,
        ...props,
      },
    });
  };

  describe('value.name', () => {
    it('renders the value name in the heading', () => {
      createComponent();

      expect(findHeading().text()).toBe('To do');
    });
  });

  describe('count', () => {
    it('renders the count alongside the work-items icon', () => {
      createComponent({ props: { count: 42 } });

      expect(findCount().text()).toBe('42');
      expect(findIconByName('work-items')).not.toBeUndefined();
    });
  });

  describe('collapse toggle', () => {
    it('renders a chevron-down toggle when expanded', () => {
      createComponent();

      expect(findCollapseToggle().props('icon')).toBe('chevron-down');
      expect(findCollapseToggle().attributes('aria-expanded')).toBe('true');
    });

    it('renders a chevron-right toggle and hides the column actions when collapsed', () => {
      createComponent({ props: { collapsed: true } });

      expect(findCollapseToggle().props('icon')).toBe('chevron-right');
      expect(findCollapseToggle().attributes('aria-expanded')).toBe('false');
      expect(findIconByName('ellipsis_v')).toBeUndefined();
      expect(findIconByName('plus')).toBeUndefined();
    });

    it('emits toggle-collapse when clicked', () => {
      createComponent();

      findCollapseToggle().vm.$emit('click');

      expect(wrapper.emitted('toggle-collapse')).toHaveLength(1);
    });

    it('points aria-controls at the region it expands and collapses', () => {
      createComponent({ props: { controlsId: 'board-column-body-42' } });

      expect(findCollapseToggle().attributes('aria-controls')).toBe('board-column-body-42');
    });
  });

  describe('drag handle', () => {
    it('does not make the header bar a drag handle by default', () => {
      createComponent();

      expect(findHeaderBar().classes()).not.toContain(DRAG_HANDLE_CLASS);
      expect(findHeaderBar().classes()).not.toContain('gl-cursor-grab');
    });

    it('turns the whole header bar into the drag handle when reorderable', () => {
      createComponent({ props: { reorderable: true } });

      expect(findHeaderBar().classes()).toContain(DRAG_HANDLE_CLASS);
      expect(findHeaderBar().classes()).toContain('gl-cursor-grab');
    });

    it('keeps the header bar as the drag handle while collapsed', () => {
      createComponent({ props: { reorderable: true, collapsed: true } });

      expect(findHeaderBar().classes()).toContain(DRAG_HANDLE_CLASS);
    });
  });

  describe('actions menu', () => {
    it('is not rendered when the column is not reorderable', () => {
      createComponent();

      expect(findActionsMenu().exists()).toBe(false);
    });

    it('is not rendered while the column is collapsed', () => {
      createComponent({ props: { reorderable: true, collapsed: true } });

      expect(findActionsMenu().exists()).toBe(false);
    });

    it('renders Move left and Move right items on a reorderable expanded column', () => {
      createComponent({ props: { reorderable: true } });

      expect(findActionsMenu().exists()).toBe(true);
      expect(
        findActionsMenu()
          .props('items')
          .map((item) => item.text),
      ).toEqual(['Move left', 'Move right']);
    });

    it('disables Move left on the first column and Move right on the last', () => {
      createComponent({ props: { reorderable: true, canMoveLeft: false, canMoveRight: true } });

      expect(findActionItem(0).extraAttrs.disabled).toBe(true);
      expect(findActionItem(1).extraAttrs.disabled).toBe(false);
    });

    it('emits move-column with a -1/+1 delta when an item is actioned', () => {
      createComponent({ props: { reorderable: true, canMoveLeft: true, canMoveRight: true } });

      findActionItem(0).action();
      findActionItem(1).action();

      expect(wrapper.emitted('move-column')).toEqual([[-1], [1]]);
    });
  });

  describe('create item button', () => {
    it('renders a plus button when canCreateWorkItem is true and the column is expanded', () => {
      createComponent({ props: { canCreateWorkItem: true } });

      expect(findCreateButton().exists()).toBe(true);
      expect(findCreateButton().props('icon')).toBe('plus');
    });

    it('is hidden when the column is collapsed', () => {
      createComponent({ props: { canCreateWorkItem: true, collapsed: true } });

      expect(findCreateButton().exists()).toBe(false);
    });

    it('emits create-item when clicked', () => {
      createComponent({ props: { canCreateWorkItem: true } });

      findCreateButton().vm.$emit('click');

      expect(wrapper.emitted('create-item')).toHaveLength(1);
    });
  });

  describe('vertical layout when collapsed', () => {
    beforeEach(() => {
      createComponent({ props: { collapsed: true } });
    });

    it('lays the title and count out vertically', () => {
      expect(findHeading().attributes('style')).toContain('writing-mode: vertical-rl');
      expect(findCount().attributes('style')).toContain('writing-mode: vertical-rl');
    });

    it('rotates the status and count icons to match the vertical text', () => {
      expect(findIconByName('status-waiting').classes()).toContain('gl-rotate-90');
      expect(findIconByName('work-items').classes()).toContain('gl-rotate-90');
    });
  });

  describe('icon decoration', () => {
    describe('when the decoration is an icon with a name', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders an icon with the decoration name', () => {
        expect(findIconByName('status-waiting')).not.toBeUndefined();
      });

      it('passes the adaptive color as inline style', () => {
        expect(getAdaptiveStatusColor).toHaveBeenCalledWith('#737278');
        expect(findIconByName('status-waiting').element.style.color).toBe('rgb(137, 136, 141)');
      });
    });

    describe('when the decoration has no color', () => {
      it('renders the icon without an inline color style', () => {
        createComponent({
          props: { decoration: { type: 'icon', name: 'status-waiting', color: null } },
        });

        expect(findIconByName('status-waiting').element.style.color).toBe('');
      });
    });

    describe('when the decoration type is not "icon"', () => {
      it('does not render an icon', () => {
        createComponent({ props: { decoration: { type: 'none' } } });

        expect(findIconByName('status-waiting')).toBeUndefined();
      });
    });

    describe('when the decoration name is empty', () => {
      it('does not render an icon', () => {
        createComponent({ props: { decoration: { type: 'icon', name: '' } } });

        expect(findIconByName('status-waiting')).toBeUndefined();
      });
    });
  });
});
