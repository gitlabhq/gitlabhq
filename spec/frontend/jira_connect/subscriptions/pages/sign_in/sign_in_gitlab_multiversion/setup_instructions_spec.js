import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormCheckbox, GlLink } from '@gitlab/ui';

import {
  PREREQUISITES_DOC_LINK,
  OAUTH_SELF_MANAGED_DOC_LINK,
  SET_UP_INSTANCE_DOC_LINK,
  JIRA_USER_REQUIREMENTS_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';
import SetupInstructions from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/setup_instructions.vue';

describe('SetupInstructions', () => {
  let wrapper;

  const findPrerequisitesGlLink = () => wrapper.findAllComponents(GlLink).at(0);
  const findOAuthGlLink = () => wrapper.findAllComponents(GlLink).at(1);
  const findSetUpInstanceGlLink = () => wrapper.findAllComponents(GlLink).at(2);
  const findJiraUserRequirementsGlLink = () => wrapper.findAllComponents(GlLink).at(3);
  const findBackButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findNextButton = () => wrapper.findAllComponents(GlButton).at(1);
  const findCheckboxAtIndex = (index) => wrapper.findAllComponents(GlFormCheckbox).at(index);

  const createComponent = () => {
    wrapper = shallowMount(SetupInstructions);
  };

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "Prerequisites" link to documentation', () => {
      expect(findPrerequisitesGlLink().attributes('href')).toBe(PREREQUISITES_DOC_LINK);
    });

    it('renders "Set up OAuth authentication" link to documentation', () => {
      expect(findOAuthGlLink().attributes('href')).toBe(OAUTH_SELF_MANAGED_DOC_LINK);
    });

    it('renders "Set up your instance" link to documentation', () => {
      expect(findSetUpInstanceGlLink().attributes('href')).toBe(SET_UP_INSTANCE_DOC_LINK);
    });

    it('renders "Jira user requirements" link to documentation', () => {
      expect(findJiraUserRequirementsGlLink().attributes('href')).toBe(
        JIRA_USER_REQUIREMENTS_DOC_LINK,
      );
    });

    describe('NextButton', () => {
      it('emits next event when clicked and all steps checked', async () => {
        createComponent();

        findCheckboxAtIndex(0).vm.$emit('input', true);
        findCheckboxAtIndex(1).vm.$emit('input', true);
        findCheckboxAtIndex(2).vm.$emit('input', true);
        findCheckboxAtIndex(3).vm.$emit('input', true);

        await nextTick();

        expect(findNextButton().attributes('disabled')).toBeUndefined();
      });

      it('disables button when not all steps are checked', () => {
        expect(findNextButton().attributes().disabled).toBe('true');
      });
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
