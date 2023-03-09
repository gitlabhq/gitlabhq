import { mount } from '@vue/test-utils';
import { zip } from 'lodash';
import { trimText } from 'helpers/text_helper';
import Deployment from '~/vue_merge_request_widget/components/deployment/deployment.vue';
import DeploymentList from '~/vue_merge_request_widget/components/deployment/deployment_list.vue';
import MrCollapsibleExtension from '~/vue_merge_request_widget/components/mr_collapsible_extension.vue';
import { mockStore } from '../mock_data';

const DEFAULT_PROPS = {
  hasDeploymentMetrics: false,
  deploymentClass: 'js-pre-deployment',
};

describe('~/vue_merge_request_widget/components/deployment/deployment_list.vue', () => {
  let wrapper;
  let propsData;

  const factory = (props = {}) => {
    propsData = {
      ...DEFAULT_PROPS,
      deployments: mockStore.deployments,
      ...props,
    };
    wrapper = mount(DeploymentList, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper?.destroy?.();
  });

  describe('with few deployments', () => {
    beforeEach(() => {
      factory();
    });

    it('shows all deployments', () => {
      const deploymentWrappers = wrapper.findAllComponents(Deployment);
      expect(wrapper.findComponent(MrCollapsibleExtension).exists()).toBe(false);
      expect(deploymentWrappers).toHaveLength(propsData.deployments.length);

      zip(deploymentWrappers.wrappers, propsData.deployments).forEach(
        ([deploymentWrapper, deployment]) => {
          expect(deploymentWrapper.props('deployment')).toEqual(deployment);
          expect(deploymentWrapper.props()).toMatchObject({
            showMetrics: DEFAULT_PROPS.hasDeploymentMetrics,
          });
          expect(deploymentWrapper.classes(DEFAULT_PROPS.deploymentClass)).toBe(true);
          expect(deploymentWrapper.text()).toEqual(expect.any(String));
          expect(deploymentWrapper.text()).not.toBe('');
        },
      );
    });
  });
  describe('with many deployments', () => {
    let deployments;
    let collapsibleExtension;

    beforeEach(() => {
      deployments = [
        ...mockStore.deployments,
        ...mockStore.deployments.map((deployment) => ({
          ...deployment,
          id: deployment.id + mockStore.deployments.length,
        })),
      ];
      factory({ deployments });

      collapsibleExtension = wrapper.findComponent(MrCollapsibleExtension);
    });

    it('shows collapsed deployments', () => {
      expect(collapsibleExtension.exists()).toBe(true);
      expect(trimText(collapsibleExtension.text())).toBe(
        `${deployments.length} environments impacted. View all environments.`,
      );
    });
    it('shows all deployments on click', async () => {
      await collapsibleExtension.find('button').trigger('click');
      const deploymentWrappers = wrapper.findAllComponents(Deployment);
      expect(deploymentWrappers).toHaveLength(deployments.length);

      zip(deploymentWrappers.wrappers, propsData.deployments).forEach(
        ([deploymentWrapper, deployment]) => {
          expect(deploymentWrapper.props('deployment')).toEqual(deployment);
          expect(deploymentWrapper.classes(DEFAULT_PROPS.deploymentClass)).toBe(true);
          expect(deploymentWrapper.text()).toEqual(expect.any(String));
          expect(deploymentWrapper.text()).not.toBe('');
        },
      );
    });
  });
});
