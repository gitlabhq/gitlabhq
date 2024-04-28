import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

describe('BoardAddNewColumnTrigger', () => {
  let wrapper;

  const findCreateButton = () => wrapper.findComponent(GlButton);

  const mountComponent = ({ isNewListShowing = false } = {}) => {
    const userCalloutDismissSpy = jest.fn();
    const shouldShowCallout = true;
    wrapper = mountExtended(BoardAddNewColumnTrigger, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
      propsData: {
        isNewListShowing,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  describe('when isNewListShowing is false', () => {
    it('shows form on click button', () => {
      expect(findCreateButton().isVisible()).toBe(true);

      findCreateButton().vm.$emit('click');

      expect(wrapper.emitted('setAddColumnFormVisibility')).toEqual([[true]]);
    });
  });
  describe('when isNewListShowing is true', () => {
    it('does not show the button', () => {
      mountComponent({ isNewListShowing: true });

      expect(findCreateButton().isVisible()).toBe(false);
    });
  });
});
