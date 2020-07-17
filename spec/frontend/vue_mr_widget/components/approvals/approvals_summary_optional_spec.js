import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import {
  OPTIONAL,
  OPTIONAL_CAN_APPROVE,
} from '~/vue_merge_request_widget/components/approvals/messages';
import ApprovalsSummaryOptional from '~/vue_merge_request_widget/components/approvals/approvals_summary_optional.vue';

const TEST_HELP_PATH = 'help/path';

describe('MRWidget approvals summary optional', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApprovalsSummaryOptional, {
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findHelpLink = () => wrapper.find(GlLink);

  describe('when can approve', () => {
    beforeEach(() => {
      createComponent({ canApprove: true, helpPath: TEST_HELP_PATH });
    });

    it('shows optional can approve message', () => {
      expect(wrapper.text()).toEqual(OPTIONAL_CAN_APPROVE);
    });

    it('shows help link', () => {
      const link = findHelpLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(TEST_HELP_PATH);
    });
  });

  describe('when cannot approve', () => {
    beforeEach(() => {
      createComponent({ canApprove: false, helpPath: TEST_HELP_PATH });
    });

    it('shows optional message', () => {
      expect(wrapper.text()).toEqual(OPTIONAL);
    });

    it('does not show help link', () => {
      expect(findHelpLink().exists()).toBe(false);
    });
  });
});
