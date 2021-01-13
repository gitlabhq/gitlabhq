import { mount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CopyEmailToClipboard from '~/sidebar/components/copy_email_to_clipboard.vue';

describe('CopyEmailToClipboard component', () => {
  const sampleEmail = 'sample+email@test.com';

  const wrapper = mount(CopyEmailToClipboard, {
    propsData: {
      copyText: sampleEmail,
    },
  });

  it('renders the Issue email text with the forwardable email', () => {
    expect(getByText(wrapper.element, `Issue email: ${sampleEmail}`)).not.toBeNull();
  });

  it('finds ClipboardButton with the correct props', () => {
    expect(wrapper.find(ClipboardButton).props('text')).toBe(sampleEmail);
  });
});
