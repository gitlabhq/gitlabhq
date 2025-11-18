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
  experimentFeaturesEnabled: true,
  paidDuoTier: true,
  duoContextExclusionSettings: {
    exclusionRules: ['*.log', 'node_modules/'],
  },
  initialDuoRemoteFlowsAvailability: false,
};

describe('GitlabDuoSettings', () => {
  let wrapper;

  const createWrapper = (props = {}, provide = {}) => {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    return mountExtended(GitlabDuoSettings, {
      propsData,
      provide: {
        glFeatures: {
          useDuoContextExclusion: true,
          duoWorkflowInCi: false,
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
  const findDuoRemoteFlowsHiddenInput = () =>
    wrapper.find('input[name="project[project_setting_attributes][duo_remote_flows_enabled]"]');
  const findDuoRemoteFlowsToggle = () => wrapper.findByTestId('duo-remote-flows-enabled');
  const findAutoReviewToggle = () => wrapper.findByTestId('amazon-q-auto-review-enabled');

  beforeEach(() => {
    wrapper = createWrapper();
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
      wrapper = createWrapper({});

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
        wrapper = createWrapper({ amazonQAvailable: false });

        expect(findAutoReviewToggle().exists()).toBe(false);
      });

      it('shows auto review toggle within Duo settings', () => {
        wrapper = createWrapper({ amazonQAvailable: true });

        expect(findAutoReviewToggle().exists()).toBe(true);
      });

      it('disables auto review toggle when Duo features are locked', () => {
        wrapper = createWrapper({
          amazonQAvailable: true,
          duoFeaturesLocked: true,
        });

        expect(findAutoReviewToggle().props('disabled')).toBe(true);
      });

      it('disables auto review toggle when Duo features are not enabled', () => {
        wrapper = createWrapper({
          amazonQAvailable: true,
          duoFeaturesEnabled: false,
        });

        expect(findAutoReviewToggle().props('disabled')).toBe(true);
      });

      it('enables auto review toggle when Amazon Q and Duo features are enabled', () => {
        wrapper = createWrapper({
          amazonQAvailable: true,
          duoFeaturesEnabled: true,
        });

        expect(findAutoReviewToggle().props('disabled')).toBe(false);
      });

      it('updates the hidden input value when toggled', async () => {
        wrapper = createWrapper({
          amazonQAvailable: true,
          amazonQAutoReviewEnabled: true,
          duoFeaturesEnabled: true,
          initialDuoRemoteFlowsAvailability: false,
        });

        const findHiddenInput = () =>
          wrapper.find('input[name="project[amazon_q_auto_review_enabled]"]');

        expect(parseBoolean(findHiddenInput().attributes('value'))).toBe(true);

        await findAutoReviewToggle().vm.$emit('change', false);

        // Vue 3 returns an empty string, while Vue 2 returns 'false'
        // That's why we parse a boolean to verify the value both for Vue 2 and Vue 3
        expect(parseBoolean(findHiddenInput().attributes('value'))).toBe(false);
      });
    });

    describe('Duo Flow settings', () => {
      describe.each`
        duoWorkflowInCi | amazonQAvailable | duoFeaturesEnabled | shouldRender | scenario
        ${false}        | ${false}         | ${true}            | ${false}     | ${'duoWorkflowInCi flag is disabled'}
        ${true}         | ${true}          | ${true}            | ${false}     | ${'Amazon Q is enabled'}
        ${true}         | ${false}         | ${false}           | ${false}     | ${'Duo features are not enabled'}
        ${true}         | ${false}         | ${true}            | ${true}      | ${'all conditions are met'}
      `(
        'when $scenario',
        ({ duoWorkflowInCi, amazonQAvailable, duoFeaturesEnabled, shouldRender }) => {
          beforeEach(() => {
            wrapper = createWrapper({ amazonQAvailable, duoFeaturesEnabled }, { duoWorkflowInCi });
          });

          it(`${shouldRender ? 'renders' : 'does not render'} the Duo remote flows toggle`, () => {
            expect(findDuoRemoteFlowsToggle().exists()).toBe(shouldRender);
          });
        },
      );

      describe('when Duo remote flows toggle is rendered', () => {
        beforeEach(() => {
          wrapper = createWrapper(
            { duoFeaturesEnabled: true, amazonQAvailable: false },
            { duoWorkflowInCi: true },
          );
        });

        it('clicking on the checkbox and submitting passes along the data to the rest call', async () => {
          const duoRemoteFlowsToggle = findDuoRemoteFlowsToggle();
          const hiddenInput = findDuoRemoteFlowsHiddenInput();

          expect(duoRemoteFlowsToggle.exists()).toBe(true);
          expect(parseBoolean(hiddenInput.attributes('value'))).toBe(false);

          await duoRemoteFlowsToggle.vm.$emit('change', true);

          expect(parseBoolean(hiddenInput.attributes('value'))).toBe(true);
        });
      });
    });

    describe('when areDuoSettingsLocked is false', () => {
      it('does not show CascadingLockIcon', () => {
        wrapper = createWrapper({ duoFeaturesLocked: false });
        expect(findDuoCascadingLockIcon().exists()).toBe(false);
      });
    });

    describe('when areDuoSettingsLocked is true', () => {
      it('shows CascadingLockIcon when duoAvailabilityCascadingSettings is provided', () => {
        wrapper = createWrapper({
          duoAvailabilityCascadingSettings: {
            lockedByAncestor: false,
            lockedByApplicationSetting: false,
            ancestorNamespace: null,
          },
          duoFeaturesLocked: true,
        });
        expect(findDuoCascadingLockIcon().exists()).toBe(true);
      });

      it('passes correct props to CascadingLockIcon', () => {
        wrapper = createWrapper({
          duoAvailabilityCascadingSettings: {
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

      it('does not show CascadingLockIcon when duoAvailabilityCascadingSettings is empty', () => {
        wrapper = createWrapper({
          duoAvailabilityCascadingSettings: {},
          duoFeaturesLocked: true,
        });
        expect(findDuoCascadingLockIcon().exists()).toBe(false);
      });

      it('does not show CascadingLockIcon when duoAvailabilityCascadingSettings is null', () => {
        wrapper = createWrapper({
          duoAvailabilityCascadingSettings: null,
          duoFeaturesLocked: true,
        });
        expect(findDuoCascadingLockIcon().exists()).toBe(false);
      });
    });
  });

  describe('Amazon Q', () => {
    it('shows Amazon Q text for duo field when Amazon Q is enabled', () => {
      wrapper = createWrapper({ amazonQAvailable: true });

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
      wrapper = createWrapper(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(true);
      expect(findExclusionSettings().props('exclusionRules')).toEqual(['*.log', 'node_modules/']);
    });

    it('does not render ExclusionSettings when duo features are not available', () => {
      wrapper = createWrapper(
        { licensedAiFeaturesAvailable: false },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(false);
    });

    it('does not render ExclusionSettings when feature flag is disabled', () => {
      wrapper = createWrapper(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: false },
      );

      expect(findExclusionSettings().exists()).toBe(false);
    });

    it('does not render ExclusionSettings when experiment features are disabled', () => {
      wrapper = createWrapper(
        {
          licensedAiFeaturesAvailable: true,
          experimentFeaturesEnabled: false,
        },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(false);
    });

    it('renders ExclusionSettings when experiment features are enabled', () => {
      wrapper = createWrapper(
        {
          licensedAiFeaturesAvailable: true,
          experimentFeaturesEnabled: true,
          paidDuoTier: true,
        },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(true);
    });

    it('does not render ExclusionSettings when paidDuoTier is false', () => {
      wrapper = createWrapper(
        {
          licensedAiFeaturesAvailable: true,
          experimentFeaturesEnabled: true,
          paidDuoTier: false,
        },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(false);
    });

    it('renders ExclusionSettings when paidDuoTier is true', () => {
      wrapper = createWrapper(
        {
          licensedAiFeaturesAvailable: true,
          experimentFeaturesEnabled: true,
          paidDuoTier: true,
        },
        { useDuoContextExclusion: true },
      );

      expect(findExclusionSettings().exists()).toBe(true);
    });

    it('updates exclusion rules when ExclusionSettings emits update', async () => {
      wrapper = createWrapper(
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
      wrapper = createWrapper(
        { licensedAiFeaturesAvailable: true },
        { useDuoContextExclusion: true },
      );
      const hiddenInputs = findExclusionRulesHiddenInputs();

      expect(hiddenInputs).toHaveLength(2);
      expect(hiddenInputs.at(0).attributes('value')).toBe('*.log');
      expect(hiddenInputs.at(1).attributes('value')).toBe('node_modules/');
    });

    it('updates hidden inputs when exclusion rules change', async () => {
      wrapper = createWrapper(
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
      wrapper = createWrapper(
        {
          licensedAiFeaturesAvailable: true,
          experimentFeaturesEnabled: true,
          duoContextExclusionSettings: { exclusionRules: [] },
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
      wrapper = createWrapper(
        {
          licensedAiFeaturesAvailable: true,
          experimentFeaturesEnabled: true,
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

      wrapper = createWrapper(
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
