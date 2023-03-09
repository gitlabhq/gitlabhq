import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import dismissibleContainer from '~/vue_shared/components/dismissible_container.vue';

describe('DismissibleContainer', () => {
  let wrapper;
  const propsData = {
    path: 'some/path',
    featureId: 'some-feature-id',
  };

  describe('template', () => {
    const findBtn = () => wrapper.find('[data-testid="close"]');
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      wrapper = shallowMount(dismissibleContainer, { propsData });
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('successfully dismisses', () => {
      mockAxios.onPost(propsData.path).replyOnce(HTTP_STATUS_OK);
      const button = findBtn();

      button.trigger('click');

      expect(wrapper.emitted().dismiss).toEqual(expect.any(Array));
    });
  });

  describe('slots', () => {
    const slots = {
      title: 'Foo Title',
      default: 'default slot',
    };

    it.each(Object.keys(slots))('renders the %s slot', (slot) => {
      const slotContent = slots[slot];
      wrapper = shallowMount(dismissibleContainer, {
        propsData,
        slots: {
          [slot]: `<span>${slotContent}</span>`,
        },
      });

      expect(wrapper.text()).toContain(slotContent);
    });
  });
});
