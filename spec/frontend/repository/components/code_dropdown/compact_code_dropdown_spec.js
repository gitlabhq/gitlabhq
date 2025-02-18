import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CompactCodeDropdown from '~/repository/components/code_dropdown/compact_code_dropdown.vue';
import CodeDropdownCloneItem from '~/repository/components/code_dropdown/code_dropdown_clone_item.vue';
import CodeDropdownDownloadItems from '~/repository/components/code_dropdown/code_dropdown_download_items.vue';
import CodeDropdownIdeItem from '~/repository/components/code_dropdown/code_dropdown_ide_item.vue';
import { stubComponent } from 'helpers/stub_component';
import {
  mockIdeItems,
  expectedSourceCodeItems,
  expectedDirectoryDownloadItems,
} from 'jest/repository/components/code_dropdown/mock_data';

describe('Compact Code Dropdown coomponent', () => {
  let wrapper;
  const sshUrl = 'ssh://foo.bar';
  const httpUrl = 'http://foo.bar';
  const httpsUrl = 'https://foo.bar';
  const xcodeUrl = 'xcode://foo.bar';
  const currentPath = null;
  const directoryDownloadLinks = [
    { text: 'zip', path: `${httpUrl}/archive.zip` },
    { text: 'tar.gz', path: `${httpUrl}/archive.tar.gz` },
    { text: 'tar.bz2', path: `${httpUrl}/archive.tar.bz2` },
    { text: 'tar', path: `${httpUrl}/archive.tar` },
  ];
  const defaultPropsData = {
    sshUrl,
    httpUrl,
    xcodeUrl,
    currentPath,
    directoryDownloadLinks,
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const findCodeDropdownCloneItems = () => wrapper.findAllComponents(CodeDropdownCloneItem);
  const findCodeDropdownCloneItemAtIndex = (index) => findCodeDropdownCloneItems().at(index);

  const findCodeDropdownIdeItems = () => wrapper.findAllComponents(CodeDropdownIdeItem);
  const findCodeDropdownIdeItemAtIndex = (index) => findCodeDropdownIdeItems().at(index);
  const findCodeDropdownDownloadItems = () => wrapper.findAllComponents(CodeDropdownDownloadItems);
  const findCodeDropdownDownloadItemAtIndex = (index) => findCodeDropdownDownloadItems().at(index);

  const closeDropdown = jest.fn();

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CompactCodeDropdown, {
      propsData,
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: {
            close: closeDropdown,
          },
        }),
      },
    });
  };

  describe('copyGroup', () => {
    describe('rendering', () => {
      it('should not render if link does not exist', () => {
        createComponent({ sshUrl: undefined, httpUrl: undefined, kerberosUrl: undefined });
        expect(findCodeDropdownCloneItems().exists()).toBe(false);
      });

      it.each`
        name      | index | link
        ${'SSH'}  | ${0}  | ${sshUrl}
        ${'HTTP'} | ${1}  | ${httpUrl}
      `('renders correct link and a copy-button for $name', ({ index, link }) => {
        createComponent();

        const item = findCodeDropdownCloneItemAtIndex(index);
        expect(item.props('link')).toBe(link);
      });

      it.each`
        name         | value
        ${'sshUrl'}  | ${sshUrl}
        ${'httpUrl'} | ${httpUrl}
      `('does not fail if only $name is set', ({ name, value }) => {
        createComponent({ [name]: value });

        expect(findCodeDropdownCloneItemAtIndex(0).props('link')).toBe(value);
      });
    });

    describe('functionality', () => {
      it.each`
        name         | value
        ${'sshUrl'}  | ${null}
        ${'httpUrl'} | ${null}
      `('allows null values for the props', ({ name, value }) => {
        createComponent({ ...defaultPropsData, [name]: value });

        expect(findCodeDropdownCloneItems()).toHaveLength(1);
      });

      it('correctly calculates httpLabel for HTTPS protocol', () => {
        createComponent({ httpUrl: httpsUrl });

        expect(findCodeDropdownCloneItemAtIndex(0).attributes('label')).toContain('HTTPS');
      });

      it.each`
        name      | index | link
        ${'SSH'}  | ${0}  | ${sshUrl}
        ${'HTTP'} | ${1}  | ${httpUrl}
      `('does not close dropdown on $name item click', () => {
        createComponent();
        expect(findDropdown().props('autoClose')).toBe(false);
      });
    });
  });

  describe('ideGroup', () => {
    it('should not render if ideGroup is empty', () => {
      createComponent({ xcodeUrl: undefined, sshUrl: undefined, httpUrl: undefined });
      expect(findCodeDropdownIdeItems().exists()).toBe(false);
    });

    it('renders with correct props', () => {
      createComponent();
      expect(findCodeDropdownIdeItems()).toHaveLength(3);

      mockIdeItems.forEach((item, index) => {
        const ideItem = findCodeDropdownIdeItemAtIndex(index);
        expect(ideItem.props('ideItem')).toStrictEqual(item);
      });
    });
  });

  describe('sourceCodeGroup', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render if directoryDownloadLinks is empty', () => {
      createComponent({ directoryDownloadLinks: [] });
      expect(findCodeDropdownDownloadItems().exists()).toBe(false);
    });

    it('renders with correct props', () => {
      expect(findCodeDropdownDownloadItems()).toHaveLength(1);

      const item = findCodeDropdownDownloadItemAtIndex(0);
      expect(item.props('items')).toStrictEqual(expectedSourceCodeItems);
    });

    it('closes dropdown when event is emitted', () => {
      findCodeDropdownDownloadItemAtIndex(0).vm.$emit('close-dropdown');
      expect(closeDropdown).toHaveBeenCalled();
    });
  });

  describe('directoryDownloadLinksGroup', () => {
    beforeEach(() => {
      createComponent({ ...defaultPropsData, currentPath: '/subdir' });
    });

    it('should not render if currentPath does not exist and directoryDownloadLinks is empty', () => {
      createComponent({ directoryDownloadLinks: [], currentPath: undefined });
      expect(findCodeDropdownDownloadItems().exists()).toBe(false);
    });

    it('renders with correct props', () => {
      expect(findCodeDropdownDownloadItems()).toHaveLength(2);

      const item = findCodeDropdownDownloadItemAtIndex(1);
      expect(item.props('items')).toStrictEqual(expectedDirectoryDownloadItems);
    });

    it('closes dropdown when event is emitted', () => {
      findCodeDropdownDownloadItemAtIndex(1).vm.$emit('close-dropdown');
      expect(closeDropdown).toHaveBeenCalled();
    });
  });
});
