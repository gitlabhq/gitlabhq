import { shallowMount } from '@vue/test-utils';
import { GlFormInput } from '@gitlab/ui';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';

const placeholderText = 'Test Button Text';

describe('ReplyPlaceholder', () => {
  let wrapper;

  const createComponent = ({ options = {} } = {}) => {
    wrapper = shallowMount(DiscussionReplyPlaceholder, {
      propsData: {
        placeholderText,
      },
      ...options,
    });
  };

  const findInput = () => wrapper.findComponent(GlFormInput);

  it('emits focus event on button click', async () => {
    createComponent({ options: { attachTo: document.body } });

    await findInput().vm.$emit('focus');

    expect(wrapper.emitted()).toEqual({
      focus: [[]],
    });
  });

  it('should render reply input', () => {
    createComponent();

    expect(findInput().attributes('placeholder')).toEqual(placeholderText);
  });
});
