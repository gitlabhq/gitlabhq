import { nextTick } from 'vue';
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import CommitListItemOverflowMenu from '~/projects/commits/components/commit_list_item_overflow_menu.vue';
import { mockCommit } from './mock_data';

describe('CommitListItemOverflowMenu', () => {
  let wrapper;

  const mockToastShow = jest.fn();

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CommitListItemOverflowMenu, {
      propsData: {
        commit: mockCommit,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);

  const findViewDetailsItem = () => wrapper.findByTestId('view-commit-details');
  const findCopyShaItem = () => wrapper.findByTestId('copy-commit-sha');
  const findBrowseFilesItem = () => wrapper.findByTestId('browse-files');

  describe('dropdown button', () => {
    it('renders with correct props', () => {
      const dropdown = findDisclosureDropdown();

      expect(dropdown.props()).toMatchObject({
        icon: 'ellipsis_v',
        toggleText: 'Commit actions',
        textSrOnly: true,
        noCaret: true,
        category: 'tertiary',
      });
    });

    it('has tooltip directive applied', () => {
      const dropdown = findDisclosureDropdown();
      const tooltipBinding = getBinding(dropdown.element, 'gl-tooltip');

      expect(tooltipBinding.value).toBe('Actions');
    });
  });

  describe('dropdown items', () => {
    it('renders all dropdown items', () => {
      expect(findDropdownItems()).toHaveLength(3);
    });

    describe('view commit details item', () => {
      it('has correct text and icon', () => {
        const viewDetailsItem = findViewDetailsItem();

        expect(viewDetailsItem.props('item')).toMatchObject({
          text: 'View commit details',
          icon: 'commit',
          href: mockCommit.webPath,
        });
      });
    });

    describe('copy commit SHA item', () => {
      it('has correct text and icon', () => {
        const copyShaItem = findCopyShaItem();

        expect(copyShaItem.props('item')).toMatchObject({
          text: 'Copy commit SHA',
          icon: 'copy-to-clipboard',
          action: expect.any(Function),
        });
      });

      it('shows successful toast on copy', async () => {
        const copyShaItem = findCopyShaItem();

        copyShaItem.props('item').action();
        await nextTick();

        expect(mockToastShow).toHaveBeenCalledWith('Commit SHA copied to clipboard.');
      });
    });
  });

  describe('browse files item', () => {
    it('has correct text and icon', () => {
      const browseFilesItem = findBrowseFilesItem();

      expect(browseFilesItem.props('item')).toMatchObject({
        text: 'Browse files at this commit',
        icon: 'folder-open',
        href: mockCommit.webUrl,
      });
    });
  });
});
