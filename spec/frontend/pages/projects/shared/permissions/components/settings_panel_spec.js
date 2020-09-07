import { shallowMount, mount } from '@vue/test-utils';

import settingsPanel from '~/pages/projects/shared/permissions/components/settings_panel.vue';
import {
  featureAccessLevel,
  visibilityLevelDescriptions,
  visibilityOptions,
} from '~/pages/projects/shared/permissions/constants';
import projectFeatureSetting from '~/pages/projects/shared/permissions/components/project_feature_setting.vue';
import projectFeatureToggle from '~/vue_shared/components/toggle_button.vue';

const defaultProps = {
  currentSettings: {
    visibilityLevel: 10,
    requestAccessEnabled: true,
    issuesAccessLevel: 20,
    repositoryAccessLevel: 20,
    forkingAccessLevel: 20,
    mergeRequestsAccessLevel: 20,
    buildsAccessLevel: 20,
    wikiAccessLevel: 20,
    snippetsAccessLevel: 20,
    pagesAccessLevel: 10,
    containerRegistryEnabled: true,
    lfsEnabled: true,
    emailsDisabled: false,
    packagesEnabled: true,
    showDefaultAwardEmojis: true,
  },
  canDisableEmails: true,
  canChangeVisibilityLevel: true,
  allowedVisibilityOptions: [0, 10, 20],
  visibilityHelpPath: '/help/public_access/public_access',
  registryAvailable: false,
  registryHelpPath: '/help/user/packages/container_registry/index',
  lfsAvailable: true,
  lfsHelpPath: '/help/topics/git/lfs/index',
  lfsObjectsExist: false,
  lfsObjectsRemovalHelpPath: `/help/topics/git/lfs/index#removing-objects-from-lfs`,
  pagesAvailable: true,
  pagesAccessControlEnabled: false,
  pagesAccessControlForced: false,
  pagesHelpPath: '/help/user/project/pages/introduction#gitlab-pages-access-control',
  packagesAvailable: false,
  packagesHelpPath: '/help/user/packages/index',
};

describe('Settings Panel', () => {
  let wrapper;

  const mountComponent = (
    { currentSettings = {}, ...customProps } = {},
    mountFn = shallowMount,
  ) => {
    const propsData = {
      ...defaultProps,
      ...customProps,
      currentSettings: { ...defaultProps.currentSettings, ...currentSettings },
    };

    return mountFn(settingsPanel, {
      propsData,
    });
  };

  const overrideCurrentSettings = (currentSettingsProps, extraProps = {}) => {
    return mountComponent({ ...extraProps, currentSettings: currentSettingsProps });
  };

  const findLFSSettingsRow = () => wrapper.find({ ref: 'git-lfs-settings' });
  const findLFSSettingsMessage = () => findLFSSettingsRow().find('p');
  const findLFSFeatureToggle = () => findLFSSettingsRow().find(projectFeatureToggle);

  const findRepositoryFeatureProjectRow = () => wrapper.find({ ref: 'repository-settings' });
  const findRepositoryFeatureSetting = () =>
    findRepositoryFeatureProjectRow().find(projectFeatureSetting);

  beforeEach(() => {
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Project Visibility', () => {
    it('should set the project visibility help path', () => {
      expect(wrapper.find({ ref: 'project-visibility-settings' }).props().helpPath).toBe(
        defaultProps.visibilityHelpPath,
      );
    });

    it('should not disable the visibility level dropdown', () => {
      wrapper.setProps({ canChangeVisibilityLevel: true });

      return wrapper.vm.$nextTick(() => {
        expect(
          wrapper.find('[name="project[visibility_level]"]').attributes().disabled,
        ).toBeUndefined();
      });
    });

    it('should disable the visibility level dropdown', () => {
      wrapper.setProps({ canChangeVisibilityLevel: false });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('[name="project[visibility_level]"]').attributes().disabled).toBe(
          'disabled',
        );
      });
    });

    it.each`
      option                        | allowedOptions                                                                       | disabled
      ${visibilityOptions.PRIVATE}  | ${[visibilityOptions.PRIVATE, visibilityOptions.INTERNAL, visibilityOptions.PUBLIC]} | ${false}
      ${visibilityOptions.PRIVATE}  | ${[visibilityOptions.INTERNAL, visibilityOptions.PUBLIC]}                            | ${true}
      ${visibilityOptions.INTERNAL} | ${[visibilityOptions.PRIVATE, visibilityOptions.INTERNAL, visibilityOptions.PUBLIC]} | ${false}
      ${visibilityOptions.INTERNAL} | ${[visibilityOptions.PRIVATE, visibilityOptions.PUBLIC]}                             | ${true}
      ${visibilityOptions.PUBLIC}   | ${[visibilityOptions.PRIVATE, visibilityOptions.INTERNAL, visibilityOptions.PUBLIC]} | ${false}
      ${visibilityOptions.PUBLIC}   | ${[visibilityOptions.PRIVATE, visibilityOptions.INTERNAL]}                           | ${true}
    `(
      'sets disabled to $disabled for the visibility option $option when given $allowedOptions',
      ({ option, allowedOptions, disabled }) => {
        wrapper.setProps({ allowedVisibilityOptions: allowedOptions });

        return wrapper.vm.$nextTick(() => {
          const attributeValue = wrapper
            .find(`[name="project[visibility_level]"] option[value="${option}"]`)
            .attributes().disabled;

          if (disabled) {
            expect(attributeValue).toBe('disabled');
          } else {
            expect(attributeValue).toBeUndefined();
          }
        });
      },
    );

    it('should set the visibility level description based upon the selected visibility level', () => {
      wrapper.find('[name="project[visibility_level]"]').setValue(visibilityOptions.INTERNAL);

      expect(wrapper.find({ ref: 'project-visibility-settings' }).text()).toContain(
        visibilityLevelDescriptions[visibilityOptions.INTERNAL],
      );
    });

    it('should show the request access checkbox if the visibility level is not private', () => {
      wrapper = overrideCurrentSettings({ visibilityLevel: visibilityOptions.INTERNAL });

      expect(wrapper.find('[name="project[request_access_enabled]"]').exists()).toBe(true);
    });

    it('should not show the request access checkbox if the visibility level is private', () => {
      wrapper = overrideCurrentSettings({ visibilityLevel: visibilityOptions.PRIVATE });

      expect(wrapper.find('[name="project[request_access_enabled]"]').exists()).toBe(false);
    });
  });

  describe('Repository', () => {
    it('should set the repository help text when the visibility level is set to private', () => {
      wrapper = overrideCurrentSettings({ visibilityLevel: visibilityOptions.PRIVATE });

      expect(findRepositoryFeatureProjectRow().props().helpText).toBe(
        'View and edit files in this project',
      );
    });

    it('should set the repository help text with a read access warning when the visibility level is set to non-private', () => {
      wrapper = overrideCurrentSettings({ visibilityLevel: visibilityOptions.PUBLIC });

      expect(findRepositoryFeatureProjectRow().props().helpText).toBe(
        'View and edit files in this project. Non-project members will only have read access',
      );
    });
  });

  describe('Merge requests', () => {
    it('should enable the merge requests access level input when the repository is enabled', () => {
      wrapper = overrideCurrentSettings({ repositoryAccessLevel: featureAccessLevel.EVERYONE });

      expect(
        wrapper
          .find('[name="project[project_feature_attributes][merge_requests_access_level]"]')
          .props().disabledInput,
      ).toBe(false);
    });

    it('should disable the merge requests access level input when the repository is disabled', () => {
      wrapper = overrideCurrentSettings({ repositoryAccessLevel: featureAccessLevel.NOT_ENABLED });

      expect(
        wrapper
          .find('[name="project[project_feature_attributes][merge_requests_access_level]"]')
          .props().disabledInput,
      ).toBe(true);
    });
  });

  describe('Forks', () => {
    it('should enable the forking access level input when the repository is enabled', () => {
      wrapper = overrideCurrentSettings({ repositoryAccessLevel: featureAccessLevel.EVERYONE });

      expect(
        wrapper.find('[name="project[project_feature_attributes][forking_access_level]"]').props()
          .disabledInput,
      ).toBe(false);
    });

    it('should disable the forking access level input when the repository is disabled', () => {
      wrapper = overrideCurrentSettings({ repositoryAccessLevel: featureAccessLevel.NOT_ENABLED });

      expect(
        wrapper.find('[name="project[project_feature_attributes][forking_access_level]"]').props()
          .disabledInput,
      ).toBe(true);
    });
  });

  describe('Pipelines', () => {
    it('should enable the builds access level input when the repository is enabled', () => {
      wrapper = overrideCurrentSettings({ repositoryAccessLevel: featureAccessLevel.EVERYONE });

      expect(
        wrapper.find('[name="project[project_feature_attributes][builds_access_level]"]').props()
          .disabledInput,
      ).toBe(false);
    });

    it('should disable the builds access level input when the repository is disabled', () => {
      wrapper = overrideCurrentSettings({ repositoryAccessLevel: featureAccessLevel.NOT_ENABLED });

      expect(
        wrapper.find('[name="project[project_feature_attributes][builds_access_level]"]').props()
          .disabledInput,
      ).toBe(true);
    });
  });

  describe('Container registry', () => {
    it('should show the container registry settings if the registry is available', () => {
      wrapper.setProps({ registryAvailable: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'container-registry-settings' }).exists()).toBe(true);
      });
    });

    it('should hide the container registry settings if the registry is not available', () => {
      wrapper.setProps({ registryAvailable: false });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'container-registry-settings' }).exists()).toBe(false);
      });
    });

    it('should set the container registry settings help path', () => {
      wrapper.setProps({ registryAvailable: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'container-registry-settings' }).props().helpPath).toBe(
          defaultProps.registryHelpPath,
        );
      });
    });

    it('should show the container registry public note if the visibility level is public and the registry is available', () => {
      wrapper = overrideCurrentSettings(
        { visibilityLevel: visibilityOptions.PUBLIC },
        { registryAvailable: true },
      );

      expect(wrapper.find({ ref: 'container-registry-settings' }).text()).toContain(
        'Note: the container registry is always visible when a project is public',
      );
    });

    it('should hide the container registry public note if the visibility level is private and the registry is available', () => {
      wrapper = overrideCurrentSettings(
        { visibilityLevel: visibilityOptions.PRIVATE },
        { registryAvailable: true },
      );

      expect(wrapper.find({ ref: 'container-registry-settings' }).text()).not.toContain(
        'Note: the container registry is always visible when a project is public',
      );
    });

    it('should enable the container registry input when the repository is enabled', () => {
      wrapper = overrideCurrentSettings(
        { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        { registryAvailable: true },
      );

      expect(
        wrapper.find('[name="project[container_registry_enabled]"]').props().disabledInput,
      ).toBe(false);
    });

    it('should disable the container registry input when the repository is disabled', () => {
      wrapper = overrideCurrentSettings(
        { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
        { registryAvailable: true },
      );

      expect(
        wrapper.find('[name="project[container_registry_enabled]"]').props().disabledInput,
      ).toBe(true);
    });
  });

  describe('Git Large File Storage', () => {
    it('should show the LFS settings if LFS is available', () => {
      wrapper.setProps({ lfsAvailable: true });

      return wrapper.vm.$nextTick(() => {
        expect(findLFSSettingsRow().exists()).toBe(true);
      });
    });

    it('should hide the LFS settings if LFS is not available', () => {
      wrapper.setProps({ lfsAvailable: false });

      return wrapper.vm.$nextTick(() => {
        expect(findLFSSettingsRow().exists()).toBe(false);
      });
    });

    it('should set the LFS settings help path', () => {
      expect(findLFSSettingsRow().props().helpPath).toBe(defaultProps.lfsHelpPath);
    });

    it('should enable the LFS input when the repository is enabled', () => {
      wrapper = overrideCurrentSettings(
        { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        { lfsAvailable: true },
      );

      expect(findLFSFeatureToggle().props().disabledInput).toBe(false);
    });

    it('should disable the LFS input when the repository is disabled', () => {
      wrapper = overrideCurrentSettings(
        { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
        { lfsAvailable: true },
      );

      expect(findLFSFeatureToggle().props().disabledInput).toBe(true);
    });

    it('should not change lfsEnabled when disabling the repository', async () => {
      // mount over shallowMount, because we are aiming to test rendered state of toggle
      wrapper = mountComponent({ currentSettings: { lfsEnabled: true } }, mount);

      const repositoryFeatureToggleButton = findRepositoryFeatureSetting().find('button');
      const lfsFeatureToggleButton = findLFSFeatureToggle().find('button');
      const isToggleButtonChecked = toggleButton => toggleButton.classes('is-checked');

      // assert the initial state
      expect(isToggleButtonChecked(lfsFeatureToggleButton)).toBe(true);
      expect(isToggleButtonChecked(repositoryFeatureToggleButton)).toBe(true);

      repositoryFeatureToggleButton.trigger('click');
      await wrapper.vm.$nextTick();

      expect(isToggleButtonChecked(repositoryFeatureToggleButton)).toBe(false);
      // LFS toggle should still be checked
      expect(isToggleButtonChecked(lfsFeatureToggleButton)).toBe(true);
    });

    describe.each`
      lfsObjectsExist | lfsEnabled | isShown
      ${true}         | ${true}    | ${false}
      ${true}         | ${false}   | ${true}
      ${false}        | ${true}    | ${false}
      ${false}        | ${false}   | ${false}
    `(
      'with (lfsObjectsExist = $lfsObjectsExist, lfsEnabled = $lfsEnabled)',
      ({ lfsObjectsExist, lfsEnabled, isShown }) => {
        beforeEach(() => {
          wrapper = mountComponent({ lfsObjectsExist, currentSettings: { lfsEnabled } }, mount);
        });

        if (isShown) {
          it('shows warning message', () => {
            const message = findLFSSettingsMessage();
            const link = message.find('a');

            expect(message.text()).toContain(
              'LFS objects from this repository are still available to forks',
            );
            expect(link.text()).toBe('How do I remove them?');
            expect(link.attributes('href')).toBe(
              '/help/topics/git/lfs/index#removing-objects-from-lfs',
            );
          });
        } else {
          it('does not show warning message', () => {
            expect(findLFSSettingsMessage().exists()).toBe(false);
          });
        }
      },
    );
  });

  describe('Packages', () => {
    it('should show the packages settings if packages are available', () => {
      wrapper.setProps({ packagesAvailable: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'package-settings' }).exists()).toBe(true);
      });
    });

    it('should hide the packages settings if packages are not available', () => {
      wrapper.setProps({ packagesAvailable: false });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'package-settings' }).exists()).toBe(false);
      });
    });

    it('should set the package settings help path', () => {
      wrapper.setProps({ packagesAvailable: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'package-settings' }).props().helpPath).toBe(
          defaultProps.packagesHelpPath,
        );
      });
    });

    it('should enable the packages input when the repository is enabled', () => {
      wrapper = overrideCurrentSettings(
        { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        { packagesAvailable: true },
      );

      expect(wrapper.find('[name="project[packages_enabled]"]').props().disabledInput).toBe(false);
    });

    it('should disable the packages input when the repository is disabled', () => {
      wrapper = overrideCurrentSettings(
        { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
        { packagesAvailable: true },
      );

      expect(wrapper.find('[name="project[packages_enabled]"]').props().disabledInput).toBe(true);
    });
  });

  describe('Pages', () => {
    it.each`
      pagesAvailable | pagesAccessControlEnabled | visibility
      ${true}        | ${true}                   | ${'show'}
      ${true}        | ${false}                  | ${'hide'}
      ${false}       | ${true}                   | ${'hide'}
      ${false}       | ${false}                  | ${'hide'}
    `(
      'should $visibility the page settings if pagesAvailable is $pagesAvailable and pagesAccessControlEnabled is $pagesAccessControlEnabled',
      ({ pagesAvailable, pagesAccessControlEnabled, visibility }) => {
        wrapper.setProps({ pagesAvailable, pagesAccessControlEnabled });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.find({ ref: 'pages-settings' }).exists()).toBe(visibility === 'show');
        });
      },
    );

    it('should set the pages settings help path', () => {
      wrapper.setProps({ pagesAvailable: true, pagesAccessControlEnabled: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'pages-settings' }).props().helpPath).toBe(
          defaultProps.pagesHelpPath,
        );
      });
    });
  });

  describe('Email notifications', () => {
    it('should show the disable email notifications input if emails an be disabled', () => {
      wrapper.setProps({ canDisableEmails: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'email-settings' }).exists()).toBe(true);
      });
    });

    it('should hide the disable email notifications input if emails cannot be disabled', () => {
      wrapper.setProps({ canDisableEmails: false });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'email-settings' }).exists()).toBe(false);
      });
    });
  });

  describe('Default award emojis', () => {
    it('should show the "Show default award emojis" input', () => {
      return wrapper.vm.$nextTick(() => {
        expect(
          wrapper
            .find('input[name="project[project_setting_attributes][show_default_award_emojis]"]')
            .exists(),
        ).toBe(true);
      });
    });
  });

  describe('Metrics dashboard', () => {
    it('should show the metrics dashboard access toggle', () => {
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'metrics-visibility-settings' }).exists()).toBe(true);
      });
    });

    it('should set the visibility level description based upon the selected visibility level', () => {
      wrapper
        .find('[name="project[project_feature_attributes][metrics_dashboard_access_level]"]')
        .setValue(visibilityOptions.PUBLIC);

      expect(wrapper.vm.metricsDashboardAccessLevel).toBe(visibilityOptions.PUBLIC);
    });

    it('should contain help text', () => {
      expect(wrapper.find({ ref: 'metrics-visibility-settings' }).props().helpText).toBe(
        'With Metrics Dashboard you can visualize this project performance metrics',
      );
    });

    it('should disable the metrics visibility dropdown when the project visibility level changes to private', () => {
      wrapper = overrideCurrentSettings({ visibilityLevel: visibilityOptions.PRIVATE });

      const metricsSettingsRow = wrapper.find({ ref: 'metrics-visibility-settings' });

      expect(wrapper.vm.metricsOptionsDropdownEnabled).toBe(true);
      expect(metricsSettingsRow.find('select').attributes('disabled')).toBe('disabled');
    });
  });
});
