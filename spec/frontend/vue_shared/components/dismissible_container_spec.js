import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import dismissibleContainer from '~/vue_shared/components/dismissible_container.vue';

describe('DismissibleContainer', () => {
  let wrapper;
  const propsData = {
    path: 'some/path',
    featureId: 'some-feature-id',
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
      mockAxios.onPost(propsData.path).replyOnce(200);
      const button = findBtn();

      button.trigger('click');

      expect(wrapper.emitted().dismiss).toBeTruthy();
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
