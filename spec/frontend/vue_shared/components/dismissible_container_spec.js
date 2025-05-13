import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import DismissibleContainer from '~/vue_shared/components/dismissible_container.vue';

describe('DismissibleContainer', () => {
  let wrapper;

  const defaultProps = {
    path: 'some/path',
    featureId: 'some-feature-id',
  };

  const createComponent = ({ slots = {} } = {}) => {
    wrapper = shallowMountExtended(DismissibleContainer, {
      propsData: { ...defaultProps },
      slots,
    });
  };

  describe('template', () => {
    const findBtn = () => wrapper.findByTestId('close');
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      createComponent();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('successfully dismisses', () => {
      mockAxios.onPost(defaultProps.path).replyOnce(HTTP_STATUS_OK);
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
      createComponent({
        slots: {
          [slot]: `<span>${slotContent}</span>`,
        },
      });

      expect(wrapper.text()).toContain(slotContent);
    });
  });
});
