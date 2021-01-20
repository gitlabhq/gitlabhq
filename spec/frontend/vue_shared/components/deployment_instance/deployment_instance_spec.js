import { shallowMount } from '@vue/test-utils';
import DeployBoardInstance from '~/vue_shared/components/deployment_instance.vue';
import { folder } from './mock_data';

describe('Deploy Board Instance', () => {
  let wrapper;

  const createComponent = (props = {}) =>
    shallowMount(DeployBoardInstance, {
      propsData: {
        status: 'succeeded',
        ...props,
      },
    });

  describe('as a non-canary deployment', () => {
    afterEach(() => {
      wrapper.destroy();
    });

    it('should render a div with the correct css status and tooltip data', () => {
      wrapper = createComponent({
        logsPath: folder.logs_path,
        tooltipText: 'This is a pod',
      });

      expect(wrapper.classes('deployment-instance-succeeded')).toBe(true);
      expect(wrapper.attributes('title')).toEqual('This is a pod');
    });

    it('should render a div without tooltip data', (done) => {
      wrapper = createComponent({
        status: 'deploying',
        tooltipText: '',
      });

      wrapper.vm.$nextTick(() => {
        expect(wrapper.classes('deployment-instance-deploying')).toBe(true);
        expect(wrapper.attributes('title')).toEqual('');
        done();
      });
    });

    it('should have a log path computed with a pod name as a parameter', () => {
      wrapper = createComponent({
        logsPath: folder.logs_path,
        podName: 'tanuki-1',
      });

      expect(wrapper.vm.computedLogPath).toEqual(
        '/root/review-app/-/logs?environment_name=foo&pod_name=tanuki-1',
      );
    });
  });

  describe('as a canary deployment', () => {
    afterEach(() => {
      wrapper.destroy();
    });

    it('should render a div with canary class when stable prop is provided as false', (done) => {
      wrapper = createComponent({
        stable: false,
      });

      wrapper.vm.$nextTick(() => {
        expect(wrapper.classes('deployment-instance-canary')).toBe(true);
        done();
      });
    });
  });

  describe('as a legend item', () => {
    afterEach(() => {
      wrapper.destroy();
    });

    it('should not be a link without a logsPath prop', (done) => {
      wrapper = createComponent({
        stable: false,
        logsPath: '',
      });

      wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.computedLogPath).toBeNull();
        expect(wrapper.vm.isLink).toBeFalsy();
        done();
      });
    });

    it('should render a link without href if path is not passed', () => {
      wrapper = createComponent();

      expect(wrapper.attributes('href')).toBeUndefined();
    });

    it('should not have a tooltip', () => {
      wrapper = createComponent();

      expect(wrapper.attributes('title')).toEqual('');
    });
  });
});
