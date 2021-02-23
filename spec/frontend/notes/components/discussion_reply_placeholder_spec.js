import { shallowMount } from '@vue/test-utils';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';

const placeholderText = 'Test Button Text';

describe('ReplyPlaceholder', () => {
  let wrapper;

  const findTextarea = () => wrapper.find({ ref: 'textarea' });

  beforeEach(() => {
    wrapper = shallowMount(ReplyPlaceholder, {
      propsData: {
        placeholderText,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('emits focus event on button click', () => {
    findTextarea().trigger('focus');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted()).toEqual({
        focus: [[]],
      });
    });
  });

  it('should render reply button', () => {
    expect(findTextarea().attributes('placeholder')).toEqual(placeholderText);
  });
});
