import { GlToggle, GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProtectionToggle from '~/projects/settings/branch_rules/components/view/protection_toggle.vue';

describe('ProtectionToggle', () => {
  let wrapper;

  const createComponent = ({
    props = {},
    provided = {},
    glFeatures = { editBranchRules: true },
  } = {}) => {
    wrapper = shallowMountExtended(ProtectionToggle, {
      stubs: {
        GlToggle,
        GlIcon,
        GlLink,
        GlSprintf,
      },
      provide: {
        glFeatures,
        ...provided,
      },
      propsData: {
        dataTestIdPrefix: 'force-push',
        label: 'Force Push',
        iconTitle: 'icon title',
        isProtected: false,
        isLoading: false,
        ...props,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findIcon = () => wrapper.findByTestId('force-push-icon');

  describe('when user can edit', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the toggle', () => {
      expect(findToggle().exists()).toBe(true);
    });

    it('does not render the protection icon', () => {
      expect(findIcon().exists()).toBe(false);
    });

    it('does not render the toggle description when not provided', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('renders the toggle description, when protection is on', () => {
      createComponent({ props: { isProtected: true, description: 'Some description' } });

      expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
    });
  });

  describe('when glFeatures.editBranchRules is false', () => {
    beforeEach(() => {
      createComponent({ glFeatures: { editBranchRules: false } });
    });

    it('does not render the toggle even for users with edit privileges', () => {
      expect(findToggle().exists()).toBe(false);
    });

    it('does not render the toggle description when not provided', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });
  });
});
