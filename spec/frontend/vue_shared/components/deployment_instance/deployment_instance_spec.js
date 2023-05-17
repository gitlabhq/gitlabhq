import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DeployBoardInstance from '~/vue_shared/components/deployment_instance.vue';

describe('Deploy Board Instance', () => {
  let wrapper;

  const createComponent = (props = {}, provide) =>
    shallowMount(DeployBoardInstance, {
      propsData: {
        status: 'succeeded',
        ...props,
      },
      provide: {
        ...provide,
      },
    });

  describe('as a non-canary deployment', () => {
    it('should render a div with the correct css status and tooltip data', () => {
      wrapper = createComponent({
        tooltipText: 'This is a pod',
      });

      expect(wrapper.classes('deployment-instance-succeeded')).toBe(true);
      expect(wrapper.attributes('title')).toEqual('This is a pod');
    });

    it('should render a div without tooltip data', async () => {
      wrapper = createComponent({
        status: 'deploying',
        tooltipText: '',
      });

      await nextTick();
      expect(wrapper.classes('deployment-instance-deploying')).toBe(true);
      expect(wrapper.attributes('title')).toEqual('');
    });
  });

  describe('as a canary deployment', () => {
    it('should render a div with canary class when stable prop is provided as false', async () => {
      wrapper = createComponent({
        stable: false,
      });

      await nextTick();
      expect(wrapper.classes('deployment-instance-canary')).toBe(true);
    });
  });

  describe('as a legend item', () => {
    it('should not have a tooltip', () => {
      wrapper = createComponent();

      expect(wrapper.attributes('title')).toEqual('');
    });
  });
});
