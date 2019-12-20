import { shallowMount } from '@vue/test-utils';
import RequestWarning from '~/performance_bar/components/request_warning.vue';

describe('request warning', () => {
  const htmlId = 'request-123';

  describe('when the request has warnings', () => {
    const wrapper = shallowMount(RequestWarning, {
      propsData: {
        htmlId,
        warnings: ['gitaly calls: 30 over 10', 'gitaly duration: 1500 over 1000'],
      },
    });

    it('adds a warning emoji with the correct ID', () => {
      expect(wrapper.find('span[id]').attributes('id')).toEqual(htmlId);
      expect(wrapper.find('span[id] gl-emoji').element.dataset.name).toEqual('warning');
    });
  });

  describe('when the request does not have warnings', () => {
    const wrapper = shallowMount(RequestWarning, {
      propsData: {
        htmlId,
        warnings: [],
      },
    });

    it('does nothing', () => {
      expect(wrapper.isEmpty()).toBe(true);
    });
  });
});
