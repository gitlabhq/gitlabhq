import { shallowMount } from '@vue/test-utils';
import CopyEmailToClipboard from '~/sidebar/components/copy_email_to_clipboard.vue';
import CopyableField from '~/vue_shared/components/sidebar/copyable_field.vue';

describe('CopyEmailToClipboard component', () => {
  const mockIssueEmailAddress = 'sample+email@test.com';

  const wrapper = shallowMount(CopyEmailToClipboard, {
    propsData: {
      issueEmailAddress: mockIssueEmailAddress,
    },
  });

  it('sets CopyableField `value` prop to issueEmailAddress', () => {
    expect(wrapper.find(CopyableField).props('value')).toBe(mockIssueEmailAddress);
  });
});
