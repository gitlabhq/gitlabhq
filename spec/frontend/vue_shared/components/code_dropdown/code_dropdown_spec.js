import { GlFormInputGroup, GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import CloneDropdownItem from '~/vue_shared/components/clone_dropdown/clone_dropdown_item.vue';

describe('Clone Dropdown Button', () => {
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

  const findCloneDropdownItems = () => wrapper.findAllComponents(CloneDropdownItem);
  const findCloneDropdownItemAtIndex = (index) => findCloneDropdownItems().at(index);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CodeDropdown, {
      propsData,
      stubs: {
        GlFormInputGroup,
        GlDisclosureDropdownGroup,
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

        const item = findCloneDropdownItemAtIndex(index);
        expect(item.props('link')).toBe(link);
      });

      it.each`
        name         | value
        ${'sshUrl'}  | ${sshUrl}
        ${'httpUrl'} | ${httpUrl}
      `('does not fail if only $name is set', ({ name, value }) => {
        createComponent({ [name]: value });

        expect(findCloneDropdownItemAtIndex(0).props('link')).toBe(value);
      });
    });

    describe('functionality', () => {
      it.each`
        name         | value
        ${'sshUrl'}  | ${null}
        ${'httpUrl'} | ${null}
      `('allows null values for the props', ({ name, value }) => {
        createComponent({ ...defaultPropsData, [name]: value });

        expect(findCloneDropdownItems().length).toBe(1);
      });

      it('correctly calculates httpLabel for HTTPS protocol', () => {
        createComponent({ httpUrl: httpsUrl });

        expect(findCloneDropdownItemAtIndex(0).attributes('label')).toContain('HTTPS');
      });
    });
  });

  describe('ideGroup', () => {
    it.each`
      name                            | index | href
      ${'Visual Studio Code (SSH)'}   | ${0}  | ${encodedSshUrl}
      ${'Visual Studio Code (HTTPS)'} | ${1}  | ${encodedHttpUrl}
      ${'IntelliJ IDEA (SSH)'}        | ${2}  | ${encodedSshUrl}
      ${'IntelliJ IDEA (HTTPS)'}      | ${3}  | ${encodedHttpUrl}
      ${'Xcode'}                      | ${4}  | ${xcodeUrl}
    `('renders correct values for $name', ({ name, index, href }) => {
      createComponent();

      const item = findDropdownItemAtIndex(index);
      expect(item.props('item').text).toBe(name);
      expect(item.props('item').href).toContain(href);
    });
  });

  describe('sourceCodeGroup', () => {
    it.each(
      directoryDownloadLinks.map((directoryDownloadLink, i) => [i + 5, directoryDownloadLink]),
    )('renders correct values for $name', (index, directoryDownloadLink) => {
      createComponent();

      const item = findDropdownItemAtIndex(index);
      expect(item.props('item').text).toBe(directoryDownloadLink.text);
      expect(item.props('item').href).toBe(directoryDownloadLink.path);
    });
  });

  describe('directoryDownloadLinksGroup', () => {
    it('renders directory download links if currentPath is set', () => {
      createComponent({ ...defaultPropsData, currentPath: '/subdir' });

      expect(findDropdownItems().length).toEqual(13);
    });

    it.each(
      directoryDownloadLinks.map((directoryDownloadLink, i) => [i + 9, directoryDownloadLink]),
    )('renders correct values for $name directory link', (index, directoryDownloadLink) => {
      const subPath = '/subdir';

      createComponent({ ...defaultPropsData, currentPath: subPath });

      const item = findDropdownItemAtIndex(index);
      expect(item.props('item').text).toBe(directoryDownloadLink.text);
      expect(item.props('item').href).toBe(`${directoryDownloadLink.path}?path=${subPath}`);
    });
  });
});
