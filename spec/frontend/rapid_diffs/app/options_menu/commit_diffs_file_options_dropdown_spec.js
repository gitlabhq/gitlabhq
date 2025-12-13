import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import CommitDiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/commit_diffs_file_options_dropdown.vue';

Vue.use(PiniaVuePlugin);

describe('CommitDiffFileOptionsDropdown', () => {
  let wrapper;
  let pinia;
  let store;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(CommitDiffFileOptionsDropdown, {
      propsData: {
        items: [{ text: 'View file', href: '/file' }],
        oldPath: 'file.js',
        newPath: 'file.js',
        ...props,
      },
      pinia,
    });
  };

  const findToggleCommentButton = () => wrapper.findByTestId('toggle-comment-button');

  beforeEach(() => {
    pinia = createTestingPinia({ stubActions: false });
    store = useDiffDiscussions();
  });

  describe('when file has no discussions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes groups with only base items', () => {
      const dropdown = wrapper.findComponent(DiffFileOptionsDropdown);
      expect(dropdown.props('items')).toHaveLength(1);
      expect(dropdown.props('items')[0].items).toEqual([{ text: 'View file', href: '/file' }]);
    });
  });

  describe('when file has discussions', () => {
    beforeEach(() => {
      store.setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'file.js', new_path: 'file.js' },
          notes: [],
          hidden: false,
        },
      ]);
      createComponent();
    });

    it('includes toggle comments item in a bordered group', () => {
      const dropdown = wrapper.findComponent(DiffFileOptionsDropdown);
      expect(dropdown.props('items')).toHaveLength(2);
      expect(findToggleCommentButton().exists()).toBe(true);
      expect(findToggleCommentButton().text()).toBe('Hide comments on this file');
    });

    it('shows "Hide comments" when discussions are visible', () => {
      expect(findToggleCommentButton().text()).toBe('Hide comments on this file');
    });

    it('shows "Show comments" when discussions are hidden', async () => {
      store.discussions[0].hidden = true;

      await nextTick();

      expect(findToggleCommentButton().text()).toBe('Show comments on this file');
    });
  });

  describe('toggleComments', () => {
    beforeEach(() => {
      store.setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'file.js', new_path: 'file.js' },
          notes: [],
          hidden: false,
        },
      ]);
      createComponent();
    });

    it('calls store action to hide discussions when currently visible', () => {
      jest.spyOn(store, 'setFileDiscussionsHidden');

      findToggleCommentButton().trigger('click');

      expect(store.setFileDiscussionsHidden).toHaveBeenCalledWith('file.js', 'file.js', true);
    });

    it('calls store action to show discussions when currently hidden', async () => {
      store.discussions[0].hidden = true;
      await nextTick();

      jest.spyOn(store, 'setFileDiscussionsHidden');

      findToggleCommentButton().trigger('click');

      expect(store.setFileDiscussionsHidden).toHaveBeenCalledWith('file.js', 'file.js', false);
    });

    it('calls to close dropdown', () => {
      const closeAndFocusSpy = jest.spyOn(
        wrapper.findComponent(DiffFileOptionsDropdown).vm,
        'closeAndFocus',
      );

      findToggleCommentButton().trigger('click');

      expect(closeAndFocusSpy).toHaveBeenCalled();
    });
  });
});
