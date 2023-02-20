import { mount } from '@vue/test-utils';
import AttachmentsWarning from '~/notes/components/attachments_warning.vue';

describe('Attachments Warning Component', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(AttachmentsWarning);
  });

  it('shows warning', () => {
    const expected =
      'Attachments are sent by email. Attachments over 10 MB are sent as links to your GitLab instance, and only accessible to project members.';
    expect(wrapper.text()).toBe(expected);
  });
});
