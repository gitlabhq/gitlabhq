import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportFromGithubApp from '~/import/github/import_from_github_app.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('Import from GitHub app', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(ImportFromGithubApp, {
      provide: {
        backButtonPath: 'https://gitlab.com',
        namespaceId: '1',
        messageAdmin: 'This is an admin alert.',
        isCiCdOnly: false,
        isConfigured: true,
        buttonAuthHref: 'https://gitlab.com/submit',
        formPath: 'https://gitlab.com/submit',
        ...provide,
      },
    });
  };

  const findMultiStepForm = () => wrapper.findComponent(MultiStepFormTemplate);
  const findGithubAuthButton = () => wrapper.findByTestId('github-auth-button');
  const findAlert = () => wrapper.findComponent(GlAlert);

  it('renders a form', () => {
    createComponent();

    expect(findMultiStepForm().exists()).toBe(true);
  });

  describe('not a ci/cd project', () => {
    it('renders a button if github is configured', () => {
      createComponent();

      expect(findGithubAuthButton().exists()).toBe(true);
      expect(findAlert().exists()).toBe(false);
    });

    it('renders an alert if github is not configured', () => {
      createComponent({ isConfigured: false });

      expect(findGithubAuthButton().exists()).toBe(false);
      expect(findAlert().exists()).toBe(true);
    });

    it('does not add a ci_cd_only hidden input', () => {
      createComponent({ isCiCdOnly: false });

      const hiddenInput = wrapper.find('input[name="ci_cd_only"]');
      expect(hiddenInput.exists()).toBe(false);
    });
  });

  describe('is a ci/cd project', () => {
    it('does not render a github auth button or alert', () => {
      createComponent({ isCiCdOnly: true });

      expect(findGithubAuthButton().exists()).toBe(false);
      expect(findAlert().exists()).toBe(false);
    });

    it('adds a ci_cd_only hidden input', () => {
      createComponent({ isCiCdOnly: true });

      const hiddenInput = wrapper.find('input[name="ci_cd_only"]');
      expect(hiddenInput.exists()).toBe(true);
      expect(hiddenInput.attributes()).toEqual(
        expect.objectContaining({
          type: 'hidden',
          value: 'true',
          id: 'ci_cd_only',
        }),
      );
    });
  });
});
