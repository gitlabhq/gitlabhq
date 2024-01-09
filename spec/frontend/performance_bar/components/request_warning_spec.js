import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RequestWarning from '~/performance_bar/components/request_warning.vue';

Vue.config.ignoredElements = ['gl-emoji'];

describe('request warning', () => {
  let wrapper;
  const htmlId = 'request-123';

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(RequestWarning, {
      propsData,
      stubs: {
        GlEmoji: { template: `<div id="${htmlId}" />` },
      },
    });
  };

  const findEmoji = () => wrapper.findByTestId('warning');

  describe('when the request has warnings', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          htmlId,
          warnings: ['gitaly calls: 30 over 10', 'gitaly duration: 1500 over 1000'],
        },
      });
    });

    it('adds a warning emoji with the correct ID', () => {
      expect(findEmoji().attributes('id')).toEqual(htmlId);
      expect(findEmoji().element.dataset.name).toEqual('warning');
    });
  });

  describe('when the request does not have warnings', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          htmlId,
          warnings: [],
        },
      });
    });

    it('does nothing', () => {
      expect(findEmoji().exists()).toBe(false);
    });
  });
});
