import { GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import { createStore } from '~/boards/stores';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

Vue.use(Vuex);

describe('BoardAddNewColumnTrigger', () => {
  let wrapper;

  const findBoardsCreateList = () => wrapper.findByTestId('boards-create-list');
  const findTooltipText = () => getBinding(findBoardsCreateList().element, 'gl-tooltip');

  const mountComponent = () => {
    wrapper = mountExtended(BoardAddNewColumnTrigger, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      store: createStore(),
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
      const button = wrapper.findComponent(GlButton);

      expect(button.props('disabled')).toBe(false);
    });
  });

  describe('when button is disabled', () => {
    it('shows the tooltip', async () => {
      wrapper.findComponent(GlButton).vm.$emit('click');

      await nextTick();

      const tooltip = findTooltipText();

      expect(tooltip.value).toBe('The list creation wizard is already open');
    });
  });
});
