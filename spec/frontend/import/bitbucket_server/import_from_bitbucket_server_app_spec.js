import { nextTick } from 'vue';
import { GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import importFromBitbucketServerApp from '~/import/bitbucket_server/import_from_bitbucket_server_app.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('Import from Bitbucket Server app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(importFromBitbucketServerApp, {
      propsData: {
        backButtonPath: '/projects/new#import_project',
        formPath: '/import/bitbucket_server/configure',
      },
      stubs: {
        GlFormInput,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepForm = () => wrapper.findComponent(MultiStepFormTemplate);
  const findForm = () => wrapper.find('form');
  const findUrlInput = () => wrapper.findByTestId('url-input');
  const findUsernameInput = () => wrapper.findByTestId('username-input');
  const findTokenInput = () => wrapper.findByTestId('token-input');
  const findBackButton = () => wrapper.findByTestId('back-button');
  const findNextButton = () => wrapper.findByTestId('next-button');

  describe('form', () => {
    it('renders the multi step form correctly', () => {
      expect(findMultiStepForm().props()).toMatchObject({
        currentStep: 3,
        stepsTotal: 4,
      });
    });

    it('renders the form element correctly', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe('/import/bitbucket_server/configure');
      expect(form.find('input[type=hidden][name=authenticity_token]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('does not submit the form without required fields', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      findForm().trigger('submit');
      expect(submitSpy).not.toHaveBeenCalled();
    });

    it('submits the form with valid form data', async () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      await findUrlInput().setValue('https://your-bitbucket-server');
      await findUsernameInput().setValue('username');
      await findTokenInput().setValue('863638293ddkdl29');
      await nextTick();

      findForm().trigger('submit');
      expect(submitSpy).toHaveBeenCalledWith();
    });
  });

  describe('validation', () => {
    it('shows an error message when url is cleared', async () => {
      findUrlInput().setValue('');
      findUrlInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('url-group');
      expect(formGroup.attributes('invalid-feedback')).toBe(
        'Please enter a valid Bitbucket Server URL.',
      );
    });

    it('shows an error message when username is cleared', async () => {
      findUsernameInput().setValue('');
      findUsernameInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('username-group');
      expect(formGroup.attributes('invalid-feedback')).toBe('Please enter a valid username.');
    });

    it('shows an error message when token is cleared', async () => {
      findTokenInput().setValue('');
      findTokenInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('token-group');
      expect(formGroup.attributes('invalid-feedback')).toBe('Please enter a valid token.');
    });
  });

  describe('back button', () => {
    it('renders a back button', () => {
      expect(findBackButton().exists()).toBe(true);
      expect(findBackButton().attributes('href')).toBe('/projects/new#import_project');
    });
  });

  describe('next button', () => {
    it('renders a button', () => {
      expect(findNextButton().exists()).toBe(true);
      expect(findNextButton().attributes('type')).toBe('submit');
    });
  });
});
