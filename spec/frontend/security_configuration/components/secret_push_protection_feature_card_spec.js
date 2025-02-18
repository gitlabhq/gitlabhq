import { GlCard, GlToggle, GlLink, GlIcon, GlPopover, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SecretPushProtectionFeatureCard from '~/security_configuration/components/secret_push_protection_feature_card.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import ProjectPreReceiveSecretDetection from '~/security_configuration/graphql/set_pre_receive_secret_detection.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { secretPushProtectionMock } from '../mock_data';

Vue.use(VueApollo);

const setMockResponse = {
  data: {
    setPreReceiveSecretDetection: {
      preReceiveSecretDetectionEnabled: true,
      errors: [],
    },
  },
};
const feature = secretPushProtectionMock;

const defaultProvide = {
  secretPushProtectionAvailable: true,
  secretPushProtectionEnabled: false,
  userIsProjectAdmin: true,
  projectFullPath: 'flightjs/flight',
  secretDetectionConfigurationPath: 'flightjs/Flight/-/security/configuration/secret_detection',
};

describe('SecretPushProtectionFeatureCard component', () => {
  let wrapper;
  let apolloProvider;
  let requestHandlers;

  const createMockApolloProvider = () => {
    requestHandlers = {
      setMutationHandler: jest.fn().mockResolvedValue(setMockResponse),
    };
    return createMockApollo([
      [ProjectPreReceiveSecretDetection, requestHandlers.setMutationHandler],
    ]);
  };

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    apolloProvider = createMockApolloProvider();

    wrapper = extendedWrapper(
      shallowMount(SecretPushProtectionFeatureCard, {
        propsData: {
          feature,
          ...props,
        },
        provide: {
          ...defaultProvide,
          ...provide,
        },
        apolloProvider,
        stubs: {
          GlCard,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findLink = () => wrapper.findComponent(GlLink);
  const findLockIcon = () => wrapper.findComponent(GlIcon);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findSettingsButton = () => wrapper.findComponent(GlButton);

  it('renders correct name and description', () => {
    expect(wrapper.text()).toContain(feature.name);
    expect(wrapper.text()).toContain(feature.description);
  });

  it('shows the help link', () => {
    const link = findLink();
    expect(link.text()).toBe('Learn more.');
    expect(link.attributes('href')).toBe(feature.helpPath);
  });

  it('shows the settings button with correct icon and link', () => {
    const { secretDetectionConfigurationPath } = defaultProvide;
    const button = findSettingsButton();

    expect(button.exists()).toBe(true);
    expect(button.props('icon')).toBe('settings');
    expect(button.attributes('href')).toBe(secretDetectionConfigurationPath);
  });

  describe('when feature is available', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders toggle in correct default state', () => {
      expect(findToggle().props('disabled')).toBe(false);
      expect(findToggle().props('value')).toBe(false);
    });

    it('does not render lock icon', () => {
      expect(findLockIcon().exists()).toBe(false);
    });

    it('calls mutation on toggle change with correct payload', async () => {
      expect(findToggle().props('value')).toBe(false);
      findToggle().vm.$emit('change', true);

      expect(requestHandlers.setMutationHandler).toHaveBeenCalledWith({
        input: {
          namespacePath: defaultProvide.projectFullPath,
          enable: true,
        },
      });

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(wrapper.text()).toContain('Enabled');
    });
  });

  describe('when feature is not availabe', () => {
    describe('when instance setting is disabled', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            secretPushProtectionAvailable: false,
          },
        });
      });

      it('renders correct text', () => {
        expect(wrapper.text()).toContain('Not enabled');
      });

      it('should show disabled toggle', () => {
        expect(findToggle().props('disabled')).toBe(true);
      });

      it('renders lock icon', () => {
        expect(findLockIcon().exists()).toBe(true);
        expect(findLockIcon().props('name')).toBe('lock');
      });

      it('shows correct tootlip', () => {
        expect(findPopover().exists()).toBe(true);
        expect(findPopover().text()).toBe(
          'This feature has been disabled at the instance level. Please reach out to your instance administrator to request activation.',
        );
      });
    });

    describe('when feature is not available with current license', () => {
      beforeEach(() => {
        createComponent({
          props: {
            feature: {
              ...secretPushProtectionMock,
              available: false,
            },
          },
        });
      });
      it('should display correct message', () => {
        expect(wrapper.text()).toContain('Available with Ultimate');
      });

      it('should not render toggle', () => {
        expect(findToggle().exists()).toBe(false);
      });

      it('should not render lock icon', () => {
        expect(findLockIcon().exists()).toBe(false);
      });
    });
  });
});
