import { mount } from '@vue/test-utils';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';

describe('DiffFileOptionsDropdown', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    // mount is used because this component depends on DOM that's rendered by dropdown components
    wrapper = mount(DiffFileOptionsDropdown, { propsData });
  };

  const findDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);

  describe('with flat items', () => {
    beforeEach(() => {
      createComponent({ items: [{ text: 'View file' }, { text: 'Download' }] });
    });

    it('renders items without groups', () => {
      expect(findDropdownGroups()).toHaveLength(0);
      expect(findDropdownItems()).toHaveLength(2);
    });

    it('shows options', () => {
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
      expect(findDropdownItems()).toHaveLength(3);
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

  it('focuses toggle', () => {
    const spy = jest.spyOn(HTMLButtonElement.prototype, 'focus');
    createComponent({ items: [{ text: 'View file' }] });
    expect(spy).toHaveBeenCalled();
  });
});
