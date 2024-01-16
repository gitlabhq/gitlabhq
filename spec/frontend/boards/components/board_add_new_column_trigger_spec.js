import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('BoardAddNewColumnTrigger', () => {
  let wrapper;

  const findBoardsCreateList = () => wrapper.findByTestId('boards-create-list');
  const findTooltipText = () => getBinding(findBoardsCreateList().element, 'gl-tooltip');
  const findCreateButton = () => wrapper.findComponent(GlButton);

  const mountComponent = ({ isNewListShowing = false } = {}) => {
    wrapper = mountExtended(BoardAddNewColumnTrigger, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        isNewListShowing,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  describe('when button is active', () => {
    it('does not show the tooltip', () => {
      const tooltip = findTooltipText();

      expect(tooltip.value).toBe('');
    });

    it('renders an enabled button', () => {
      expect(findCreateButton().props('disabled')).toBe(false);
    });

    it('shows form on click button', () => {
      findCreateButton().vm.$emit('click');

      expect(wrapper.emitted('setAddColumnFormVisibility')).toEqual([[true]]);
    });
  });

  describe('when button is disabled', () => {
    it('shows the tooltip', () => {
      mountComponent({ isNewListShowing: true });

      const tooltip = findTooltipText();

      expect(tooltip.value).toBe('The list creation wizard is already open');
    });
  });
});
