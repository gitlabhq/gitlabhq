import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GitlabDuoSettings from '~/pages/projects/shared/permissions/components/gitlab_duo_settings.vue';
import ExclusionSettings from '~/pages/projects/shared/permissions/components/exclusion_settings.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

const defaultProps = {
  projectId: 123,
  projectFullPath: 'namespace/project',
  duoFeaturesEnabled: true,
  amazonQAvailable: false,
  amazonQAutoReviewEnabled: false,
  duoFeaturesLocked: false,
  licensedAiFeaturesAvailable: true,
  duoContextExclusionSettings: {
    exclusion_rules: ['*.log', 'node_modules/'],
  },
};

describe('GitlabDuoSettings', () => {
  let wrapper;

  const mountComponent = (props = {}, provide = {}, mountFn = mountExtended) => {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    return mountFn(GitlabDuoSettings, {
      propsData,
      provide: {
        glFeatures: {
          useDuoContextExclusion: true,
          ...provide,
        },
      },
    });
  };

  const findCard = () => wrapper.findByTestId('gitlab-duo-settings');
  const findSaveButton = () => wrapper.findByTestId('gitlab-duo-save-button');
  const findDuoSettings = () => wrapper.findByTestId('duo-settings');
  const findDuoCascadingLockIcon = () => wrapper.findByTestId('duo-cascading-lock-icon');
  const findExclusionSettings = () => wrapper.findComponent(ExclusionSettings);
  const findExclusionRulesHiddenInputs = () =>
    wrapper.findAll(
      'input[name="project[project_setting_attributes][duo_context_exclusion_settings][exclusion_rules][]"]',
    );

  beforeEach(() => {
    wrapper = mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
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
        helpPath: '/help/user/gitlab_duo/_index',
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
      it('shows CascadingLockIcon when cascadingSettingsData is provided', () => {
        wrapper = mountComponent({
          cascadingSettingsData: {
            lockedByAncestor: false,
            lockedByApplicationSetting: false,
            ancestorNamespace: null,
          },
          duoFeaturesLocked: true,
        });
        expect(findDuoCascadingLockIcon().exists()).toBe(true);
      });

      it('passes correct props to CascadingLockIcon', () => {
        wrapper = mountComponent({
          cascadingSettingsData: {
            lockedByAncestor: false,
            lockedByApplicationSetting: false,
            ancestorNamespace: null,
          },
          duoFeaturesLocked: true,
        });
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

  describe('ExclusionSettings', () => {
    it('renders ExclusionSettings component when duo features are available', () => {
      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(true);
      expect(findExclusionSettings().props('exclusionRules')).toEqual(['*.log', 'node_modules/']);
    });

    it('does not render ExclusionSettings when duo features are not available', () => {
      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: false },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(false);
    });

    it('does not render ExclusionSettings when feature flag is disabled', () => {
      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: false },
      );

      expect(findExclusionSettings().exists()).toBe(false);
    });

    it('updates exclusion rules when ExclusionSettings emits update', async () => {
      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );
      const newRules = ['*.log', 'node_modules/', '*.tmp'];

      const exclusionSettings = findExclusionSettings();
      expect(exclusionSettings.exists()).toBe(true);

      await exclusionSettings.vm.$emit('update', newRules);

      expect(wrapper.vm.exclusionRules).toEqual(newRules);
    });

    it('renders hidden inputs for exclusion rules form submission', () => {
      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );
      const hiddenInputs = findExclusionRulesHiddenInputs();

      expect(hiddenInputs).toHaveLength(2);
      expect(hiddenInputs.at(0).attributes('value')).toBe('*.log');
      expect(hiddenInputs.at(1).attributes('value')).toBe('node_modules/');
    });

    it('updates hidden inputs when exclusion rules change', async () => {
      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );
      const newRules = ['*.tmp', 'cache/'];

      const exclusionSettings = findExclusionSettings();
      expect(exclusionSettings.exists()).toBe(true);

      await exclusionSettings.vm.$emit('update', newRules);

      const hiddenInputs = findExclusionRulesHiddenInputs();
      expect(hiddenInputs).toHaveLength(2);
      expect(hiddenInputs.at(0).attributes('value')).toBe('*.tmp');
      expect(hiddenInputs.at(1).attributes('value')).toBe('cache/');

      const nullHiddenInput = wrapper.findByTestId('exclusion-rule-input-null');
      expect(nullHiddenInput.exists()).toBe(false);
    });

    it('handles empty exclusion rules', () => {
      wrapper = mountComponent(
        {
          licensedAiFeaturesAvailable: true,
          duoContextExclusionSettings: { exclusion_rules: [] },
        },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(true);
      expect(findExclusionSettings().props('exclusionRules')).toEqual([]);
      expect(findExclusionRulesHiddenInputs()).toHaveLength(0);

      // Check that a null hidden input is created for empty exclusion rules
      const nullHiddenInput = wrapper.findByTestId('exclusion-rule-input-null');
      expect(nullHiddenInput.exists()).toBe(true);
    });

    it('handles missing duo context exclusion settings', () => {
      wrapper = mountComponent(
        {
          licensedAiFeaturesAvailable: true,
          duoContextExclusionSettings: {},
        },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(true);
      expect(findExclusionSettings().props('exclusionRules')).toEqual([]);
    });

    it('submits form after DOM is updated when exclusion rules are updated', async () => {
      // Create a mock form element
      const mockForm = document.createElement('form');
      const mockSubmit = jest.fn();
      mockForm.submit = mockSubmit;

      // Mock the closest method to return our mock form
      const mockClosest = jest.fn().mockReturnValue(mockForm);

      wrapper = mountComponent(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );

      // Mock the $el.closest method
      wrapper.vm.$el.closest = mockClosest;

      const newRules = ['*.log', 'node_modules/', '*.tmp'];
      const exclusionSettings = findExclusionSettings();

      // Emit the update event
      await exclusionSettings.vm.$emit('update', newRules);

      // Wait for nextTick to ensure DOM updates are processed
      await nextTick();

      // Verify that closest was called with 'form'
      expect(mockClosest).toHaveBeenCalledWith('form');

      // Verify that form.submit() was called
      expect(mockSubmit).toHaveBeenCalled();

      // Verify that exclusion rules were updated
      expect(wrapper.vm.exclusionRules).toEqual(newRules);
    });
  });
});
