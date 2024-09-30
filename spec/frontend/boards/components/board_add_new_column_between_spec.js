import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnBetween from '~/boards/components/board_add_new_column_between.vue';
import { createMockDirective } from 'helpers/vue_mock_directive';

describe('BoardAddNewColumnBetween', () => {
  let wrapper;

  const findCreateButton = () => wrapper.findByTestId('board-add-new-column-between-button');

  const mountComponent = () => {
    wrapper = mountExtended(BoardAddNewColumnBetween, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  describe('BoardAddNewColumnBetween', () => {
    it('has a button', () => {
      expect(findCreateButton().isVisible()).toBe(true);
    });
    it('shows form on click button', () => {
      findCreateButton().trigger('click');

      expect(wrapper.emitted('setAddColumnFormVisibility')).toEqual([[true]]);
    });
  });
});
