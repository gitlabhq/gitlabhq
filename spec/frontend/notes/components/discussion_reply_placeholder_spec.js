import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';

const buttonText = 'Test Button Text';

describe('ReplyPlaceholder', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);

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

  it('should emit a onClick event on button click', () => {
    findButton().vm.$emit('click');

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
