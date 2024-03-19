import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import mrStatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

describe('MR widget status icon component', () => {
  let wrapper;

  const findStatusIcon = () => wrapper.findComponent(StatusIcon);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createWrapper = (props) => {
    wrapper = shallowMount(mrStatusIcon, {
      propsData: {
        ...props,
      },
    });
  };

  describe('while loading', () => {
    it('renders loading icon', () => {
      createWrapper({ status: 'loading' });

      expect(findStatusIcon().exists()).toBe(true);
      expect(findStatusIcon().props().isLoading).toBe(true);
    });
  });

  describe('with status icon', () => {
    it('renders success status icon', () => {
      createWrapper({ status: 'success' });

      expect(findStatusIcon().exists()).toBe(true);
      expect(findStatusIcon().props().iconName).toBe('success');
    });

    it('renders failed status icon', () => {
      createWrapper({ status: 'failed' });

      expect(findStatusIcon().exists()).toBe(true);
      expect(findStatusIcon().props().iconName).toBe('failed');
    });

    it('renders merged status icon', () => {
      createWrapper({ status: 'merged' });

      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props().name).toBe('merge');
    });

    it('renders closed status icon', () => {
      createWrapper({ status: 'closed' });

      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props().name).toBe('merge-request-close');
    });

    it('renders empty status icon', () => {
      createWrapper({ status: 'empty' });

      expect(findStatusIcon().exists()).toBe(true);
      expect(findStatusIcon().props().iconName).toBe('neutral');
    });
  });
});
