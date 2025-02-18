import { nextTick } from 'vue';
import { GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportFromGiteaRoot from '~/import/gitea/import_from_gitea_root.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('Import from Gitea app', () => {
  let wrapper;

  const defaultProps = {
    backButtonPath: '/projects/new#import_project',
    namespaceId: '1',
    formPath: '/import/gitea/personal_access_token',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ImportFromGiteaRoot, {
      propsData: {
        ...defaultProps,
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
  const findGiteaHostUrlInput = () => wrapper.findByTestId('gitea-host-url-input');
  const findPersonalAccessTokenInput = () => wrapper.findByTestId('personal-access-token-input');
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

      expect(form.attributes('action')).toBe(defaultProps.formPath);
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

      await findGiteaHostUrlInput().setValue('https://test.gitea.cloud/');
      await findGiteaHostUrlInput().trigger('blur');
      await findPersonalAccessTokenInput().setValue('863638293ddkdl29');
      await findPersonalAccessTokenInput().trigger('blur');
      await nextTick();

      findForm().trigger('submit');
      expect(submitSpy).toHaveBeenCalledWith();
    });
  });

  describe('validation', () => {
    it('shows an error message when url is cleared', async () => {
      findGiteaHostUrlInput().setValue('');
      findGiteaHostUrlInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('gitea-host-url-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe('Please enter a valid Gitea host URL.');
    });

    it('shows an error message when token is cleared', async () => {
      findPersonalAccessTokenInput().setValue('');
      findPersonalAccessTokenInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('personal-access-token-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe(
        'Please enter a valid personal access token.',
      );
    });
  });

  describe('back button', () => {
    it('renders a back button', () => {
      expect(findBackButton().attributes('href')).toBe(defaultProps.backButtonPath);
    });
  });

  describe('next button', () => {
    it('renders a next button', () => {
      expect(findNextButton().attributes('type')).toBe('submit');
    });
  });
});
