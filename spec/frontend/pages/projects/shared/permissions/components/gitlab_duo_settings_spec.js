import { mountExtended } from 'helpers/vue_test_utils_helper';
import GitlabDuoSettings from '~/pages/projects/shared/permissions/components/gitlab_duo_settings.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

const defaultProps = {
  projectId: 123,
  projectFullPath: 'namespace/project',
  duoFeaturesEnabled: true,
  amazonQAvailable: false,
  amazonQAutoReviewEnabled: false,
  duoFeaturesLocked: false,
  licensedAiFeaturesAvailable: true,
};

describe('GitlabDuoSettings', () => {
  let wrapper;

  const mountComponent = (props = {}, mountFn = mountExtended) => {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    return mountFn(GitlabDuoSettings, {
      propsData,
    });
  };

  const findCard = () => wrapper.findByTestId('gitlab-duo-settings-card');
  const findSaveButton = () => wrapper.findByTestId('gitlab-duo-save-button');
  const findDuoSettings = () => wrapper.findByTestId('duo-settings');
  const findDuoCascadingLockIcon = () => wrapper.findByTestId('duo-cascading-lock-icon');

  beforeEach(() => {
    wrapper = mountComponent();
  });

  it('renders the component correctly', () => {
    expect(findCard().exists()).toBe(true);
    expect(findSaveButton().exists()).toBe(true);
  });

  it('displays the correct header text', () => {
    expect(findDuoSettings().props('label')).toContain('GitLab Duo');
  });

  it('has the correct save button properties', () => {
    expect(findSaveButton().props()).toMatchObject({
      variant: 'confirm',
    });
    expect(findSaveButton().attributes('data-testid')).toBe('gitlab-duo-save-button');
  });

  describe('Duo', () => {
    it('shows duo toggle', () => {
      wrapper = mountComponent({});

      expect(findDuoSettings().exists()).toBe(true);
      expect(findDuoSettings().props()).toEqual({
        helpPath: '/help/user/ai_features',
        helpText: 'Use AI-native features in this project.',
        label: 'GitLab Duo',
        labelFor: null,
        locked: false,
      });
    });

    describe('Auto review settings', () => {
      it('hides auto review toggle within Duo settings when Amazon Q is not available', () => {
        wrapper = mountComponent({ amazonQAvailable: false });

        const autoReviewToggle = wrapper.findByTestId('amazon_q_auto_review_enabled');
        expect(autoReviewToggle.exists()).toBe(false);
      });

      it('shows auto review toggle within Duo settings', () => {
        wrapper = mountComponent({ amazonQAvailable: true });

        const autoReviewToggle = wrapper.findByTestId('amazon_q_auto_review_enabled');
        expect(autoReviewToggle.exists()).toBe(true);
      });

      it('disables auto review toggle when Duo features are locked', () => {
        wrapper = mountComponent({
          amazonQAvailable: true,
          duoFeaturesLocked: true,
        });

        const autoReviewToggle = wrapper.findByTestId('amazon_q_auto_review_enabled');
        expect(autoReviewToggle.props('disabled')).toBe(true);
      });

      it('disables auto review toggle when Duo features are not enabled', () => {
        wrapper = mountComponent({
          amazonQAvailable: true,
          duoFeaturesEnabled: false,
        });

        const autoReviewToggle = wrapper.findByTestId('amazon_q_auto_review_enabled');
        expect(autoReviewToggle.props('disabled')).toBe(true);
      });

      it('enables auto review toggle when Amazon Q and Duo features are enabled', () => {
        wrapper = mountComponent({
          amazonQAvailable: true,
          duoFeaturesEnabled: true,
        });

        const autoReviewToggle = wrapper.findByTestId('amazon_q_auto_review_enabled');
        expect(autoReviewToggle.props('disabled')).toBe(false);
      });

      it('updates the hidden input value when toggled', async () => {
        wrapper = mountComponent({
          amazonQAvailable: true,
          amazonQAutoReviewEnabled: true,
          duoFeaturesEnabled: true,
        });

        const findHiddenInput = () =>
          wrapper.find('input[name="project[amazon_q_auto_review_enabled]"]');

        expect(parseBoolean(findHiddenInput().attributes('value'))).toBe(true);

        const autoReviewToggle = wrapper.findByTestId('amazon_q_auto_review_enabled');
        await autoReviewToggle.vm.$emit('change', false);

        // Vue 3 returns an empty string, while Vue 2 returns 'false'
        // That's why we parse a boolean to verify the value both for Vue 2 and Vue 3
        expect(parseBoolean(findHiddenInput().attributes('value'))).toBe(false);
      });
    });

    describe('when areDuoSettingsLocked is false', () => {
      it('does not show CascadingLockIcon', () => {
        wrapper = mountComponent({ duoFeaturesLocked: false });
        expect(findDuoCascadingLockIcon().exists()).toBe(false);
      });
    });

    describe('when areDuoSettingsLocked is true', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          cascadingSettingsData: {
            lockedByAncestor: false,
            lockedByApplicationSetting: false,
            ancestorNamespace: null,
          },
          duoFeaturesLocked: true,
        });
      });

      it('shows CascadingLockIcon when cascadingSettingsData is provided', () => {
        expect(findDuoCascadingLockIcon().exists()).toBe(true);
      });

      it('passes correct props to CascadingLockIcon', () => {
        expect(findDuoCascadingLockIcon().props()).toMatchObject({
          isLockedByGroupAncestor: false,
          isLockedByApplicationSettings: false,
          ancestorNamespace: null,
        });
      });

      it('does not show CascadingLockIcon when cascadingSettingsData is empty', () => {
        wrapper = mountComponent({
          cascadingSettingsData: {},
          duoFeaturesLocked: true,
        });
        expect(findDuoCascadingLockIcon().exists()).toBe(false);
      });

      it('does not show CascadingLockIcon when cascadingSettingsData is null', () => {
        wrapper = mountComponent({
          cascadingSettingsData: null,
          duoFeaturesLocked: true,
        });
        expect(findDuoCascadingLockIcon().exists()).toBe(false);
      });
    });
  });

  describe('Amazon Q', () => {
    it('shows Amazon Q text for duo field when Amazon Q is enabled', () => {
      wrapper = mountComponent({ amazonQAvailable: true });

      expect(findDuoSettings().exists()).toBe(true);
      expect(findDuoSettings().props()).toEqual({
        helpPath: '/help/user/duo_amazon_q/_index.md',
        helpText: 'This project can use Amazon Q.',
        label: 'Amazon Q',
        labelFor: null,
        locked: false,
      });
    });
  });
});
