import { shallowMount } from '@vue/test-utils';
import CommitItem from '~/diffs/components/commit_item.vue';
import CommitWidget from '~/diffs/components/commit_widget.vue';

describe('diffs/components/commit_widget', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(CommitWidget, {
      propsData: { commit: {} },
    });
  });

  it('renders commit item', () => {
    const commitElement = wrapper.findComponent(CommitItem);

    expect(commitElement.exists()).toBe(true);
  });
});
