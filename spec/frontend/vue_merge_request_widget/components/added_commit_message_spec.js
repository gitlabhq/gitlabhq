import { shallowMount } from '@vue/test-utils';
import AddedCommentMessage from '~/vue_merge_request_widget/components/added_commit_message.vue';

let wrapper;

function factory(propsData) {
  wrapper = shallowMount(AddedCommentMessage, {
    propsData: {
      isFastForwardEnabled: false,
      targetBranch: 'main',
      ...propsData,
    },
  });
}

describe('Widget added commit message', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('displays changes where not merged when state is closed', () => {
    factory({ state: 'closed' });

    expect(wrapper.element.outerHTML).toContain('The changes were not merged');
  });
});
