import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import RemoveIssue from '~/boards/components/sidebar/remove_issue.vue';

describe('boards sidebar remove issue', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);

  const createComponent = propsData => {
    wrapper = shallowMount(RemoveIssue, {
      propsData: {
        issue: {},
        list: {},
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders remove button', () => {
    expect(findButton().exists()).toBe(true);
  });
});
