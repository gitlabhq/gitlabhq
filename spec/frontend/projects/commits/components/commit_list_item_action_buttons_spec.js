import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListItemActionButtons from '~/projects/commits/components/commit_list_item_action_buttons.vue';
import ExpandCollapseButton from '~/vue_shared/components/expand_collapse_button/expand_collapse_button.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { mockCommit } from './mock_data';

describe('CommitListItemActionButtons', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CommitListItemActionButtons, {
      propsData: {
        commit: mockCommit,
        isCollapsed: true,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findBrowseFilesButton = () => wrapper.findByTestId('browse-files-button');
  const findExpandCollapseButton = () => wrapper.findComponent(ExpandCollapseButton);

  describe('commit short ID', () => {
    it('displays the commit short ID', () => {
      const commitShortId = wrapper.findByText(mockCommit.shortId);
      expect(commitShortId.exists()).toBe(true);
    });
  });

  describe('clipboard button', () => {
    it('passes correct props to clipboard button', () => {
      const clipboardButton = findClipboardButton();
      expect(clipboardButton.props('text')).toBe(mockCommit.sha);
      expect(clipboardButton.props('title')).toBe('Copy commit SHA');
      expect(clipboardButton.props('category')).toBe('tertiary');
    });
  });

  describe('browse files button', () => {
    it('has correct attributes', () => {
      const browseButton = findBrowseFilesButton();
      expect(browseButton.attributes('href')).toBe(mockCommit.webUrl);
      expect(browseButton.attributes('aria-label')).toBe('Browse commit files');
    });
  });

  describe('expand/collapse button', () => {
    it('renders with correct prop', () => {
      expect(findExpandCollapseButton().props()).toEqual({
        anchorId: '',
        isCollapsed: true,
        size: 'small',
      });
    });

    it('emits click event when clicked', async () => {
      const expandCollapseButton = findExpandCollapseButton();
      await expandCollapseButton.vm.$emit('click');
      expect(wrapper.emitted()).toEqual({ click: [[]] });
    });
  });
});
