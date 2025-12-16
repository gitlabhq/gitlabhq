import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import DiffLineDiscussions from '~/rapid_diffs/app/discussions/diff_line_discussions.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NewLineDiscussionForm from '~/rapid_diffs/app/discussions/new_line_discussion_form.vue';

describe('DiffLineDiscussions', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(DiffLineDiscussions, { propsData });
  };

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
  });

  it('shows regular discussions', () => {
    useDiffDiscussions().setInitialDiscussions([
      {
        id: '1',
        diff_discussion: true,
        position: { old_path: 'old', new_path: 'old', new_line: '1', old_line: '1' },
        notes: [{}],
      },
    ]);
    createComponent({ position: { oldPath: 'old', newPath: 'old', oldLine: '1', newLine: '1' } });
    const discussions = wrapper.findComponent(DiffDiscussions).props('discussions');
    expect(discussions).toHaveLength(1);
    expect(discussions[0]).toStrictEqual(useDiffDiscussions().discussions[0]);
  });

  it('does not show hidden discussions', () => {
    useDiffDiscussions().setInitialDiscussions([
      {
        id: '1',
        diff_discussion: true,
        hidden: true,
        position: { old_path: 'old', new_path: 'old', new_line: '1', old_line: '1' },
        notes: [{}],
      },
    ]);
    createComponent({ position: { oldPath: 'old', newPath: 'old', oldLine: '1', newLine: '1' } });
    expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(false);
  });

  it('shows new discussion form', () => {
    useDiffDiscussions().addNewLineDiscussionForm({
      oldPath: 'old',
      newPath: 'old',
      oldLine: '1',
      newLine: '1',
    });
    createComponent({ position: { oldPath: 'old', newPath: 'old', oldLine: '1', newLine: '1' } });
    expect(wrapper.findComponent(NewLineDiscussionForm).props('discussion')).toStrictEqual(
      useDiffDiscussions().discussions[0],
    );
  });
});
