import { GlToggle, GlLink, GlIcon, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PreReceiveSecretDetectionFeatureCard from '~/security_configuration/components/pre_receive_secret_detection_feature_card.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import ProjectSetPreReceiveSecretDetection from '~/security_configuration/graphql/set_pre_receive_secret_detection.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { preReceiveSecretDetectionMock } from '../mock_data';

Vue.use(VueApollo);

const setMockResponse = {
  data: {
    setPreReceiveSecretDetection: {
      preReceiveSecretDetectionEnabled: true,
      errors: [],
    },
  },
};
const feature = preReceiveSecretDetectionMock;

const defaultProvide = {
  preReceiveSecretDetectionAvailable: true,
  preReceiveSecretDetectionEnabled: false,
  userIsProjectAdmin: true,
  projectFullPath: 'flightjs/flight',
};

describe('PreReceiveSecretDetectionFeatureCard component', () => {
  let wrapper;
  let apolloProvider;
  let requestHandlers;

  const createMockApolloProvider = () => {
    requestHandlers = {
      setMutationHandler: jest.fn().mockResolvedValue(setMockResponse),
    };
    return createMockApollo([
      [ProjectSetPreReceiveSecretDetection, requestHandlers.setMutationHandler],
    ]);
  };

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    apolloProvider = createMockApolloProvider();

    wrapper = extendedWrapper(
      shallowMount(PreReceiveSecretDetectionFeatureCard, {
        propsData: {
          feature,
          ...props,
        },
        provide: {
          ...defaultProvide,
          ...provide,
        },
        apolloProvider,
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

  it('renders correct name and description', () => {
    expect(wrapper.text()).toContain(feature.name);
    expect(wrapper.text()).toContain(feature.description);
  });

  it('shows the help link', () => {
    const link = findLink();
    expect(link.text()).toBe('Learn more');
    expect(link.attributes('href')).toBe(feature.helpPath);
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
            preReceiveSecretDetectionAvailable: false,
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

    describe('FF `pre_receive_secret_detection_push_check` is disabled', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            userIsProjectAdmin: false,
          },
        });
      });

      it('should disable toggle when feature is not configured', () => {
        expect(findToggle().props('disabled')).toBe(true);
      });

      it('renders lock icon', () => {
        expect(findLockIcon().exists()).toBe(true);
        expect(findLockIcon().props('name')).toBe('lock');
      });

      it('shows correct tootlip', () => {
        expect(findPopover().exists()).toBe(true);
        expect(findPopover().text()).toBe(
          'Only a project maintainer or owner can toggle this feature.',
        );
      });
    });

    describe('when feature is not available with current license', () => {
      beforeEach(() => {
        createComponent({
          props: {
            feature: {
              ...preReceiveSecretDetectionMock,
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
