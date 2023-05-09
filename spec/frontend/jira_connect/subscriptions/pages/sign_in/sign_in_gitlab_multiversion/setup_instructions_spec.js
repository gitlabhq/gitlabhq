import { shallowMount } from '@vue/test-utils';
import { GlButton, GlLink } from '@gitlab/ui';

import { OAUTH_SELF_MANAGED_DOC_LINK } from '~/jira_connect/subscriptions/constants';
import SetupInstructions from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/setup_instructions.vue';

describe('SetupInstructions', () => {
  let wrapper;

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findBackButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findNextButton = () => wrapper.findAllComponents(GlButton).at(1);

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

    describe('when "Next" button is clicked', () => {
      it('emits "next" event', () => {
        expect(wrapper.emitted('next')).toBeUndefined();
        findNextButton().vm.$emit('click');

        expect(wrapper.emitted('next')).toHaveLength(1);
        expect(wrapper.emitted('back')).toBeUndefined();
      });
    });

    describe('when "Back" button is clicked', () => {
      it('emits "back" event', () => {
        expect(wrapper.emitted('back')).toBeUndefined();
        findBackButton().vm.$emit('click');

        expect(wrapper.emitted('back')).toHaveLength(1);
        expect(wrapper.emitted('next')).toBeUndefined();
      });
    });
  });
});
