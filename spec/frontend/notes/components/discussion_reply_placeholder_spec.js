import { shallowMount } from '@vue/test-utils';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';

const buttonText = 'Test Button Text';

describe('ReplyPlaceholder', () => {
  let wrapper;

  const findButton = () => wrapper.find({ ref: 'button' });

  beforeEach(() => {
    wrapper = shallowMount(ReplyPlaceholder, {
      propsData: {
        buttonText,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('emits onClick even on button click', () => {
    findButton().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted()).toEqual({
        onClick: [[]],
      });
    });
  });

  it('should render reply button', () => {
    expect(findButton().text()).toEqual(buttonText);
  });
});
