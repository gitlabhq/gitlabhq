import { shallowMount } from '@vue/test-utils';
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

  const findTextarea = () => wrapper.findComponent({ ref: 'textarea' });

  it('emits focus event on button click', async () => {
    createComponent({ options: { attachTo: document.body } });

    await findTextarea().trigger('focus');

    expect(wrapper.emitted()).toEqual({
      focus: [[]],
    });
  });

  it('should render reply button', () => {
    createComponent();

    expect(findTextarea().attributes('placeholder')).toEqual(placeholderText);
  });
});
