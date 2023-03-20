import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';

describe('ResolveWithIssueButton', () => {
  let wrapper;
  const url = `${TEST_HOST}/hello-world/`;

  beforeEach(() => {
    wrapper = shallowMount(ResolveWithIssueButton, {
      propsData: {
        url,
      },
    });
  });

  it('should have a link with the provided link property as href', () => {
    const button = wrapper.findComponent(GlButton);

    expect(button.attributes().href).toBe(url);
  });
});
