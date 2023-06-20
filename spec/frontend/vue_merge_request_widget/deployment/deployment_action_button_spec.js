import { GlIcon, GlLoadingIcon, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import {
  CREATED,
  RUNNING,
  DEPLOYING,
  REDEPLOYING,
  WILL_DEPLOY,
} from '~/vue_merge_request_widget/components/deployment/constants';
import DeploymentActionButton from '~/vue_merge_request_widget/components/deployment/deployment_action_button.vue';
import { actionButtonMocks } from './deployment_mock_data';

const baseProps = {
  actionsConfiguration: actionButtonMocks[DEPLOYING],
  actionInProgress: null,
  computedDeploymentStatus: CREATED,
  icon: 'play',
};

describe('Deployment action button', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = mount(DeploymentActionButton, {
      ...options,
    });
  };

  describe('when passed only icon via props', () => {
    beforeEach(() => {
      factory({
        propsData: baseProps,
        slots: {},
        stubs: {
          'gl-icon': GlIcon,
        },
      });
    });

    it('renders prop icon correctly', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
    });
  });

  describe('when passed multiple items', () => {
    beforeEach(() => {
      factory({
        propsData: baseProps,
        slots: {
          default: [`<span>${actionButtonMocks[DEPLOYING]}</span>`],
        },
        stubs: {
          'gl-icon': GlIcon,
        },
      });
    });

    it('renders slot and icon prop correctly', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
      expect(wrapper.text()).toContain(actionButtonMocks[DEPLOYING].toString());
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
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlButton).props('disabled')).toBe(true);
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
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlButton).props('disabled')).toBe(true);
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
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlButton).props('disabled')).toBe(true);
    });
  });

  describe('when no action is in progress', () => {
    beforeEach(() => {
      factory({
        propsData: baseProps,
      });
    });
    it('is not disabled nor does it show the loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlButton).props('disabled')).toBe(false);
    });
  });

  describe('when the deployment status is will_deploy', () => {
    beforeEach(() => {
      factory({
        propsData: {
          ...baseProps,
          actionInProgress: actionButtonMocks[REDEPLOYING].actionName,
          computedDeploymentStatus: WILL_DEPLOY,
        },
      });
    });
    it('is disabled and shows the loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlButton).props('disabled')).toBe(true);
    });
  });
});
