import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApprovalsSummaryOptional from '~/vue_merge_request_widget/components/approvals/approvals_summary_optional.vue';

const TEST_HELP_PATH = 'help/path';

describe('MRWidget approvals summary optional', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApprovalsSummaryOptional, {
      propsData: props,
    });
  };

  const findHelpLink = () => wrapper.findComponent(GlLink);

  describe('when can approve', () => {
    beforeEach(() => {
      createComponent({ canApprove: true, helpPath: TEST_HELP_PATH });
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

    it('does not show help link', () => {
      expect(findHelpLink().exists()).toBe(false);
    });
  });
});
