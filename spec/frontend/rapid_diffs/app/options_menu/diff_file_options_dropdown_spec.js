import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';
import * as copyToClipboard from '~/lib/utils/copy_to_clipboard';
import toast from '~/vue_shared/plugins/global_toast';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/copy_to_clipboard');
jest.mock('~/vue_shared/plugins/global_toast');

describe('DiffFileOptionsDropdown', () => {
  let wrapper;

  const defaultProps = {
    items: [],
    fileId: 'file-abc123',
    oldPath: 'app/models/user.rb',
    newPath: 'app/models/user.rb',
  };

  const createComponent = (propsData = {}) => {
    wrapper = mount(DiffFileOptionsDropdown, { propsData: { ...defaultProps, ...propsData } });
  };

  const findDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);

  describe('with flat items', () => {
    beforeEach(() => {
      createComponent({ items: [{ text: 'View file' }, { text: 'Download' }] });
    });

    it('renders items without groups', () => {
      expect(findDropdownGroups()).toHaveLength(0);
      expect(findDropdownItems()).toHaveLength(3);
    });

    it('shows copy link option', () => {
      expect(wrapper.html()).toContain('Copy link to the file');
    });

    it('shows other options', () => {
      expect(wrapper.html()).toContain('View file');
      expect(wrapper.html()).toContain('Download');
    });
  });

  describe('with grouped items', () => {
    beforeEach(() => {
      createComponent({
        items: [
          {
            name: 'File actions',
            items: [{ text: 'View file' }, { text: 'Download' }],
          },
          {
            name: 'Comments',
            bordered: true,
            items: [{ text: 'Hide comments' }],
          },
        ],
      });
    });

    it('renders groups', () => {
      expect(findDropdownGroups()).toHaveLength(2);
      expect(findDropdownItems()).toHaveLength(4);
    });

    it('shows copy link option', () => {
      expect(wrapper.html()).toContain('Copy link to the file');
    });

    it('shows all group items', () => {
      expect(wrapper.html()).toContain('View file');
      expect(wrapper.html()).toContain('Download');
      expect(wrapper.html()).toContain('Hide comments');
    });

    it('passes group properties to GlDisclosureDropdownGroup', () => {
      const groups = findDropdownGroups();
      expect(groups.at(0).props('group')).toMatchObject({
        name: 'File actions',
        items: expect.any(Array),
      });
      expect(groups.at(1).props('group')).toMatchObject({
        name: 'Comments',
        bordered: true,
        items: expect.any(Array),
      });
    });
  });

  it('renders code tags', () => {
    createComponent({ items: [{ text: 'View file at %{codeStart}abc1234%{codeEnd}' }] });
    expect(wrapper.html()).toContain('<code>abc1234</code>');
  });

  it('fills text placeholders', () => {
    createComponent({
      items: [{ text: 'View file at %{placeholder}', messageData: { placeholder: 'foo' } }],
    });
    expect(wrapper.html()).toContain('View file at foo');
  });

  it('focuses toggle', async () => {
    const spy = jest.spyOn(HTMLButtonElement.prototype, 'focus');
    createComponent({ items: [{ text: 'View file' }] });
    await nextTick();
    expect(spy).toHaveBeenCalled();
  });

  describe('copy link to file', () => {
    beforeEach(() => {
      setWindowLocation('https://example.com/merge_requests/1?view=parallel');
      createComponent();
    });

    it('copies link with file parameters and fileId hash', async () => {
      const items = findDropdownItems();
      const copyLinkItem = items.at(0);

      await copyLinkItem.props('item').action();

      expect(copyToClipboard.copyToClipboard).toHaveBeenCalledWith(
        expect.objectContaining({
          href: 'https://example.com/merge_requests/1?view=parallel&file_path=app%2Fmodels%2Fuser.rb#file-abc123',
          searchParams: expect.any(URLSearchParams),
          hash: '#file-abc123',
        }),
      );
    });

    it('shows toast notification', async () => {
      const items = findDropdownItems();
      const copyLinkItem = items.at(0);

      await copyLinkItem.props('item').action();

      expect(toast).toHaveBeenCalledWith('Link to diff file copied.');
    });
  });
});
