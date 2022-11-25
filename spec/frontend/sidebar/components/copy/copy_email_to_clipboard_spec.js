import { shallowMount } from '@vue/test-utils';
import CopyEmailToClipboard from '~/sidebar/components/copy/copy_email_to_clipboard.vue';
import CopyableField from '~/sidebar/components/copy/copyable_field.vue';

describe('CopyEmailToClipboard component', () => {
  const mockIssueEmailAddress = 'sample+email@test.com';

  const wrapper = shallowMount(CopyEmailToClipboard, {
    propsData: {
      issueEmailAddress: mockIssueEmailAddress,
    },
  });

  it('sets CopyableField `value` prop to issueEmailAddress', () => {
    expect(wrapper.findComponent(CopyableField).props('value')).toBe(mockIssueEmailAddress);
  });
});
