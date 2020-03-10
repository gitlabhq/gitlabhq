import { mount } from '@vue/test-utils';
import { GlIcon, GlLoadingIcon, GlButton } from '@gitlab/ui';
import DeploymentActionButton from '~/vue_merge_request_widget/components/deployment/deployment_action_button.vue';
import {
  CREATED,
  RUNNING,
  DEPLOYING,
  REDEPLOYING,
} from '~/vue_merge_request_widget/components/deployment/constants';
import { actionButtonMocks } from './deployment_mock_data';

const baseProps = {
  actionsConfiguration: actionButtonMocks[DEPLOYING],
  actionInProgress: null,
  computedDeploymentStatus: CREATED,
};

describe('Deployment action button', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = mount(DeploymentActionButton, {
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when passed only icon', () => {
    beforeEach(() => {
      factory({
        propsData: baseProps,
        slots: { default: ['<gl-icon name="stop" />'] },
        stubs: {
          'gl-icon': GlIcon,
        },
      });
    });

    it('renders slot correctly', () => {
      expect(wrapper.find(GlIcon).exists()).toBe(true);
    });
  });

  describe('when passed multiple items', () => {
    beforeEach(() => {
      factory({
        propsData: baseProps,
        slots: {
          default: ['<gl-icon name="play" />', `<span>${actionButtonMocks[DEPLOYING]}</span>`],
        },
        stubs: {
          'gl-icon': GlIcon,
        },
      });
    });

    it('renders slot correctly', () => {
      expect(wrapper.find(GlIcon).exists()).toBe(true);
      expect(wrapper.text()).toContain(actionButtonMocks[DEPLOYING]);
    });
  });

  describe('when its action is in progress', () => {
    beforeEach(() => {
      factory({
        propsData: {
          ...baseProps,
          actionInProgress: actionButtonMocks[DEPLOYING].actionName,
        },
      });
    });

    it('is disabled and shows the loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(GlButton).props('disabled')).toBe(true);
    });
  });

  describe('when another action is in progress', () => {
    beforeEach(() => {
      factory({
        propsData: {
          ...baseProps,
          actionInProgress: actionButtonMocks[REDEPLOYING].actionName,
        },
      });
    });
    it('is disabled and does not show the loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(GlButton).props('disabled')).toBe(true);
    });
  });

  describe('when action status is running', () => {
    beforeEach(() => {
      factory({
        propsData: {
          ...baseProps,
          actionInProgress: actionButtonMocks[REDEPLOYING].actionName,
          computedDeploymentStatus: RUNNING,
        },
      });
    });
    it('is disabled and does not show the loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(GlButton).props('disabled')).toBe(true);
    });
  });

  describe('when no action is in progress', () => {
    beforeEach(() => {
      factory({
        propsData: baseProps,
      });
    });
    it('is not disabled nor does it show the loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(GlButton).props('disabled')).toBe(false);
    });
  });
});
