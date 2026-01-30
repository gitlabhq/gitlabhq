import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WebBasedCommitSigningSettings from '~/vue_shared/components/web_based_commit_signing/settings.vue';
import WebBasedCommitSigningCheckbox from '~/vue_shared/components/web_based_commit_signing/checkbox.vue';

describe('WebBasedCommitSigningSettings', () => {
  let wrapper;

  const defaultProvide = {
    fullPath: 'gitlab-org/gitlab',
    levelId: 1,
    groupSettingsRepositoryPath: '/groups/gitlab-org/-/settings/repository',
  };

  const defaultProps = {
    initialValue: false,
    canAdminGroup: true,
    isGroupLevel: true,
  };

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMountExtended(WebBasedCommitSigningSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findCheckbox = () => wrapper.findComponent(WebBasedCommitSigningCheckbox);

  describe('template', () => {
    it('renders WebBasedCommitSigningCheckbox by default', () => {
      createComponent();

      expect(findCheckbox().exists()).toBe(true);
    });

    describe('group level', () => {
      it('passes correct props to WebBasedCommitSigningCheckbox', () => {
        createComponent({ initialValue: true, isGroupLevel: true });

        expect(findCheckbox().props()).toMatchObject({
          initialValue: true,
          hasGroupPermissions: true,
          groupSettingsRepositoryPath: defaultProvide.groupSettingsRepositoryPath,
          isGroupLevel: true,
          fullPath: defaultProvide.fullPath,
        });
      });
    });

    describe('project level', () => {
      it('passes correct props to WebBasedCommitSigningCheckbox', () => {
        createComponent({
          initialValue: true,
          canAdminGroup: true,
          groupWebBasedCommitSigningEnabled: false,
          isGroupLevel: false,
        });

        expect(findCheckbox().props()).toMatchObject({
          initialValue: true,
          hasGroupPermissions: true,
          groupSettingsRepositoryPath: defaultProvide.groupSettingsRepositoryPath,
          isGroupLevel: false,
          groupWebBasedCommitSigningEnabled: false,
          fullPath: defaultProvide.fullPath,
        });
      });
    });
  });
});
