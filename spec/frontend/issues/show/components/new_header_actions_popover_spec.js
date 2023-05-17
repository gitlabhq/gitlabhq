import { GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewHeaderActionsPopover from '~/issues/show/components/new_header_actions_popover.vue';
import { NEW_ACTIONS_POPOVER_KEY } from '~/issues/show/constants';
import { TYPE_ISSUE } from '~/issues/constants';
import * as utils from '~/lib/utils/common_utils';

describe('NewHeaderActionsPopover', () => {
  let wrapper;

  const createComponent = ({ issueType = TYPE_ISSUE, movedMrSidebarEnabled = true }) => {
    wrapper = shallowMountExtended(NewHeaderActionsPopover, {
      propsData: {
        issueType,
      },
      stubs: {
        GlPopover,
      },
      provide: {
        glFeatures: {
          movedMrSidebar: movedMrSidebarEnabled,
        },
      },
    });
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findConfirmButton = () => wrapper.findByTestId('confirm-button');

  it('should not be visible when the feature flag :moved_mr_sidebar is disabled', () => {
    createComponent({ movedMrSidebarEnabled: false });
    expect(findPopover().exists()).toBe(false);
  });

  describe('without the popover cookie', () => {
    beforeEach(() => {
      utils.setCookie = jest.fn();

      createComponent({});
    });

    it('renders the popover with correct text', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().text()).toContain('issue actions');
    });

    it('does not call setCookie', () => {
      expect(utils.setCookie).not.toHaveBeenCalled();
    });

    describe('when the confirm button is clicked', () => {
      beforeEach(() => {
        findConfirmButton().vm.$emit('click');
      });

      it('sets the popover cookie', () => {
        expect(utils.setCookie).toHaveBeenCalledWith(NEW_ACTIONS_POPOVER_KEY, true);
      });

      it('hides the popover', () => {
        expect(findPopover().exists()).toBe(false);
      });
    });
  });

  describe('with the popover cookie', () => {
    beforeEach(() => {
      jest.spyOn(utils, 'getCookie').mockReturnValue('true');

      createComponent({});
    });

    it('does not render the popover', () => {
      expect(findPopover().exists()).toBe(false);
    });
  });
});
