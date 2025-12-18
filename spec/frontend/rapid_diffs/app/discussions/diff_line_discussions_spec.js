import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { isLoggedIn } from '~/lib/utils/common_utils';
import DiffLineDiscussions from '~/rapid_diffs/app/discussions/diff_line_discussions.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NewLineDiscussionForm from '~/rapid_diffs/app/discussions/new_line_discussion_form.vue';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';

jest.mock('~/lib/utils/common_utils');

describe('DiffLineDiscussions', () => {
  let wrapper;

  const createComponent = (
    propsData = {},
    provide = { userPermissions: { can_create_note: true } },
  ) => {
    wrapper = shallowMount(DiffLineDiscussions, {
      propsData,
      provide,
    });
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

  describe('start another thread', () => {
    it('can start another thread', () => {
      isLoggedIn.mockReturnValue(true);
      useDiffDiscussions().setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'old', new_path: 'old', new_line: '1', old_line: '1' },
          notes: [{}],
        },
      ]);
      createComponent({ position: { oldPath: 'old', newPath: 'old', oldLine: '1', newLine: '1' } });
      wrapper.findComponent(GlButton).vm.$emit('click');
      expect(useDiffDiscussions().discussions[1].isForm).toBe(true);
    });

    it('shows placeholder for guests', () => {
      isLoggedIn.mockReturnValue(false);
      useDiffDiscussions().setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'old', new_path: 'old', new_line: '1', old_line: '1' },
          notes: [{}],
        },
      ]);
      createComponent({ position: { oldPath: 'old', newPath: 'old', oldLine: '1', newLine: '1' } });
      expect(wrapper.findComponent(NoteSignedOutWidget).exists()).toBe(true);
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });
});
