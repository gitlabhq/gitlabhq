import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import CommitListItemActionButtons from '~/projects/commits/components/commit_list_item_action_buttons.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { mockCommit } from './mock_data';

describe('CommitListItemActionButtons', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CommitListItemActionButtons, {
      propsData: {
        commit: mockCommit,
        isCollapsed: true,
        ...props,
      },
      stubs: {
        GlButton,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findShortIdButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findBrowseFilesButton = () => wrapper.findAllComponents(GlButton).at(1);
  const findExpandCollapseButton = () => wrapper.findAllComponents(GlButton).at(2);

  describe('commit short ID button', () => {
    it('displays the commit short ID', () => {
      expect(findShortIdButton().text()).toBe(mockCommit.shortId);
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

  describe('expand/collapse functionality', () => {
    describe('when isCollapsed is true', () => {
      beforeEach(() => {
        createComponent({ isCollapsed: true });
      });

      it('shows expand button', () => {
        expect(findExpandCollapseButton().attributes('aria-label')).toBe('Expand');
      });

      it('emits click event when expand button is clicked', async () => {
        await findExpandCollapseButton().vm.$emit('click');
        expect(wrapper.emitted()).toEqual({ click: [[]] });
      });
    });

    describe('when isCollapsed is false', () => {
      beforeEach(() => {
        createComponent({ isCollapsed: false });
      });

      it('shows collapse button', () => {
        expect(findExpandCollapseButton().attributes('aria-label')).toBe('Collapse');
      });

      it('emits click event when collapse button is clicked', async () => {
        await findExpandCollapseButton().vm.$emit('click');
        expect(wrapper.emitted()).toEqual({ click: [[]] });
      });
    });
  });
});
