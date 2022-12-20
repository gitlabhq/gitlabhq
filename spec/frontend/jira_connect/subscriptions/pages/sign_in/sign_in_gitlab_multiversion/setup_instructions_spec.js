import { shallowMount } from '@vue/test-utils';
import { GlButton, GlLink } from '@gitlab/ui';

import { OAUTH_SELF_MANAGED_DOC_LINK } from '~/jira_connect/subscriptions/constants';
import SetupInstructions from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/setup_instructions.vue';

describe('SetupInstructions', () => {
  let wrapper;

  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = shallowMount(SetupInstructions);
  };

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "Learn more" link to documentation', () => {
      expect(findGlLink().attributes('href')).toBe(OAUTH_SELF_MANAGED_DOC_LINK);
    });

    describe('when button is clicked', () => {
      it('emits "next" event', () => {
        expect(wrapper.emitted('next')).toBeUndefined();
        findGlButton().vm.$emit('click');

        expect(wrapper.emitted('next')).toHaveLength(1);
      });
    });
  });
});
