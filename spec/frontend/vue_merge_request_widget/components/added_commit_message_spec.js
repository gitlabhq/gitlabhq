import { mount } from '@vue/test-utils';
import AddedCommentMessage from '~/vue_merge_request_widget/components/added_commit_message.vue';

let wrapper;

function factory(propsData) {
  wrapper = mount(AddedCommentMessage, {
    propsData: {
      isFastForwardEnabled: false,
      targetBranch: 'main',
      ...propsData,
    },
  });
}

describe('Widget added commit message', () => {
  it('displays changes where not merged when state is closed', () => {
    factory({ state: 'closed' });

    expect(wrapper.element.outerHTML).toContain('The changes were not merged');
  });

  it('renders merge commit as a link', () => {
    factory({ state: 'merged', mergeCommitPath: 'https://test.host/merge-commit-link' });

    expect(wrapper.find('[data-testid="merge-commit-sha"]').exists()).toBe(true);
    expect(wrapper.find('[data-testid="merge-commit-sha"]').attributes('href')).toBe(
      'https://test.host/merge-commit-link',
    );
  });
});
