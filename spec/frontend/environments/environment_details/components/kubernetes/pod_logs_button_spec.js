import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PodLogsButton from '~/environments/environment_details/components/kubernetes/pod_logs_button.vue';

describe('~/environments/environment_details/components/kubernetes/pod_logs_button.vue', () => {
  let wrapper;

  const container = { name: 'my-container' };
  const otherContainer = { name: 'other-container' };
  const defaultContainers = [container, otherContainer];
  const namespace = 'my-namespace';
  const podName = 'my-pod';

  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const createWrapper = ({ containers = defaultContainers } = {}) => {
    wrapper = shallowMount(PodLogsButton, {
      propsData: {
        containers,
        namespace,
        podName,
      },
    });
  };

  describe('mounted', () => {
    describe('when there is only one container', () => {
      beforeEach(() => {
        createWrapper({ containers: [container] });
      });

      it('renders a button with the correct text', () => {
        expect(findButton().text()).toBe('View logs');
      });

      it('provides link to the logs page', () => {
        expect(findButton().attributes('to')).toBe(
          `/k8s/namespace/${namespace}/pods/${podName}/logs?container=${container.name}`,
        );
      });
    });

    describe('when there are multiple containers', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders a dropdown with the correct text', () => {
        expect(findDropdown().props('toggleText')).toBe('View logs');
      });

      it('provides correct dropdown items', () => {
        expect(findDropdown().props('items')).toEqual([
          {
            text: container.name,
            to: `/k8s/namespace/${namespace}/pods/${podName}/logs?container=${container.name}`,
          },
          {
            text: otherContainer.name,
            to: `/k8s/namespace/${namespace}/pods/${podName}/logs?container=${otherContainer.name}`,
          },
        ]);
      });
    });
  });
});
