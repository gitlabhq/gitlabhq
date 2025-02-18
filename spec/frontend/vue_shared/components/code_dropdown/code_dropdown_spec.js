import {
  GlFormInputGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import CodeDropdownCloneItem from '~/repository/components/code_dropdown/code_dropdown_clone_item.vue';

describe('Code Dropdown component', () => {
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
  const encodedSshUrl = encodeURIComponent(sshUrl);
  const encodedHttpUrl = encodeURIComponent(httpUrl);

  const findCodeDropdownCloneItems = () => wrapper.findAllComponents(CodeDropdownCloneItem);
  const findCodeDropdownCloneItemAtIndex = (index) => findCodeDropdownCloneItems().at(index);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);

  const closeDropdown = jest.fn();

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMountExtended(CodeDropdown, {
      propsData,
      stubs: {
        GlFormInputGroup,
        GlDisclosureDropdownGroup,
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
      `('does not close dropdown on $name item click', ({ index }) => {
        createComponent();

        findCodeDropdownCloneItemAtIndex(index).vm.$emit('action');

        expect(closeDropdown).not.toHaveBeenCalled();
      });
    });
  });

  describe('ideGroup', () => {
    describe.each`
      name                            | index | href
      ${'Visual Studio Code (SSH)'}   | ${0}  | ${encodedSshUrl}
      ${'Visual Studio Code (HTTPS)'} | ${1}  | ${encodedHttpUrl}
      ${'IntelliJ IDEA (SSH)'}        | ${2}  | ${encodedSshUrl}
      ${'IntelliJ IDEA (HTTPS)'}      | ${3}  | ${encodedHttpUrl}
      ${'Xcode'}                      | ${4}  | ${xcodeUrl}
    `('$name', ({ name, index, href }) => {
      beforeEach(() => {
        createComponent();
      });

      it('renders correct values', () => {
        const item = findDropdownItemAtIndex(index);

        expect(item.props('item').text).toBe(name);
        expect(item.props('item').href).toContain(href);
      });

      it('closes the dropdown on click', () => {
        findDropdownItemAtIndex(index).vm.$emit('action');

        expect(closeDropdown).toHaveBeenCalled();
      });
    });
  });

  describe('sourceCodeGroup', () => {
    describe.each(
      directoryDownloadLinks.map(({ text, path }, i) => ({
        index: i + 5,
        text,
        path,
      })),
    )('$text', ({ index, text, path }) => {
      beforeEach(() => {
        createComponent();
      });

      it('renders correct values', () => {
        const item = findDropdownItemAtIndex(index);

        expect(item.props('item').text).toBe(text);
        expect(item.props('item').href).toBe(path);
      });

      it('closes the dropdown on click', () => {
        findDropdownItemAtIndex(index).vm.$emit('action');

        expect(closeDropdown).toHaveBeenCalled();
      });
    });
  });

  describe('directoryDownloadLinksGroup', () => {
    it('renders directory download links if currentPath is set', () => {
      createComponent({ ...defaultPropsData, currentPath: '/subdir' });

      expect(findDropdownItems()).toHaveLength(13);
    });

    describe.each(
      directoryDownloadLinks.map(({ text, path }, i) => ({
        index: i + 9,
        text,
        path,
      })),
    )('$text', ({ index, text, path }) => {
      const subPath = '/subdir';

      beforeEach(() => {
        createComponent({ ...defaultPropsData, currentPath: subPath });
      });

      it('renders correct values for directory link', () => {
        const item = findDropdownItemAtIndex(index);

        expect(item.props('item').text).toBe(text);
        expect(item.props('item').href).toBe(`${path}?path=${subPath}`);
      });

      it('closes the dropdown on click', () => {
        findDropdownItemAtIndex(index).vm.$emit('action');

        expect(closeDropdown).toHaveBeenCalled();
      });
    });
  });
});
