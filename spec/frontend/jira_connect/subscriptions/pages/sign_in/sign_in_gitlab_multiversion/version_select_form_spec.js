import { GlFormInput, GlFormRadioGroup, GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VersionSelectForm from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/version_select_form.vue';

describe('VersionSelectForm', () => {
  let wrapper;

  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);

  const submitForm = () => findForm().vm.$emit('submit', new Event('submit'));

  const createComponent = () => {
    wrapper = shallowMountExtended(VersionSelectForm);
  };

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('selects saas radio option by default', () => {
      expect(findFormRadioGroup().vm.$attrs.checked).toBe(VersionSelectForm.radioOptions.saas);
    });

    it('does not render instance input', () => {
      expect(findInput().exists()).toBe(false);
    });

    describe('when form is submitted', () => {
      it('emits "submit" event with gitlab.com as the payload', () => {
        submitForm();

        expect(wrapper.emitted('submit')[0][0]).toBe('https://gitlab.com');
      });
    });
  });

  describe('when "self-managed" radio option is selected', () => {
    beforeEach(async () => {
      createComponent();

      findFormRadioGroup().vm.$emit('input', VersionSelectForm.radioOptions.selfManaged);
      await nextTick();
    });

    it('reveals the self-managed input field', () => {
      expect(findInput().exists()).toBe(true);
    });

    describe('when form is submitted', () => {
      it('emits "submit" event with the input field value as the payload', () => {
        const mockInstanceUrl = 'https://gitlab.example.com';

        findInput().vm.$emit('input', mockInstanceUrl);
        submitForm();

        expect(wrapper.emitted('submit')[0][0]).toBe(mockInstanceUrl);
      });
    });
  });
});
