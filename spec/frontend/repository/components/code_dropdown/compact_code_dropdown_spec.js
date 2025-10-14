import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
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
import {
  CODE_DROPDOWN_CLICK,
  OPEN_VSCODE_SSH,
  OPEN_VSCODE_HTTPS,
  OPEN_INTELLIJ_SSH,
  OPEN_INTELLIJ_HTTPS,
  COPY_SSH_CLONE_URL,
  COPY_HTTPS_CLONE_URL,
} from '~/repository/components/code_dropdown/constants';

jest.mock('~/tracking', () => ({
  InternalEvents: {
    mixin: () => ({
      methods: {
        trackEvent: jest.fn(),
      },
    }),
  },
}));

describe('Compact Code Dropdown component', () => {
  let wrapper;
  let trackingSpy;

  const sshUrl = 'ssh://foo.bar';
  const httpUrl = 'http://foo.bar';
  const httpsUrl = 'https://foo.bar';
  const xcodeUrl = 'xcode://foo.bar';
  const webIdeUrl = 'webIdeUrl://foo.bar';
  const gitpodUrl = 'gitpodUrl://foo.bar';
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
    webIdeUrl,
    gitpodUrl,
    showWebIdeButton: true,
    isGitpodEnabledForUser: true,
    isGitpodEnabledForInstance: true,
    currentPath,
    directoryDownloadLinks,
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findDropdownGroupAtIndex = (index) => findDropdownGroups().at(index);

  const findCodeDropdownCloneItems = () => wrapper.findAllComponents(CodeDropdownCloneItem);
  const findCodeDropdownCloneItemAtIndex = (index) => findCodeDropdownCloneItems().at(index);

  const findCodeDropdownIdeItems = () => wrapper.findAllComponents(CodeDropdownIdeItem);
  const findCodeDropdownIdeItemAtIndex = (index) => findCodeDropdownIdeItems().at(index);
  const findCodeDropdownDownloadItems = () => wrapper.findAllComponents(CodeDropdownDownloadItems);
  const findCodeDropdownDownloadItemAtIndex = (index) => findCodeDropdownDownloadItems().at(index);

  const closeDropdown = jest.fn();

  const createComponent = (propsData) => {
    trackingSpy = jest.fn();

    wrapper = shallowMount(CompactCodeDropdown, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: {
            close: closeDropdown,
          },
        }),
      },
      mixins: [
        {
          methods: {
            trackEvent: trackingSpy,
          },
        },
      ],
    });
  };

  afterEach(() => {
    wrapper?.destroy();
  });

  it('tracks CODE_DROPDOWN_CLICK when dropdown is shown', () => {
    createComponent();

    findDropdown().vm.$emit('shown');

    expect(trackingSpy).toHaveBeenCalledWith(CODE_DROPDOWN_CLICK);
  });

  describe('groups computed property', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets bordered=false for the first visible group', () => {
      expect(findDropdownGroupAtIndex(0).props('bordered')).toBe(false);
    });

    it('sets bordered=true for subsequent visible groups', () => {
      const dropdownGroups = findDropdownGroups();
      for (let i = 1; i < dropdownGroups.length; i += 1) {
        expect(findDropdownGroupAtIndex(i).props('bordered')).toBe(true);
      }
    });
  });

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
        createComponent({ sshUrl: undefined, httpUrl: undefined, [name]: value });

        expect(findCodeDropdownCloneItemAtIndex(0).props('link')).toBe(value);
      });

      // tests for calling tracking covered in code_dropdown/code_dropdown_clone_item_spec.js
      it('passes correct tracking prop', () => {
        createComponent();
        expect(findCodeDropdownCloneItemAtIndex(0).props('tracking')).toMatchObject({
          action: COPY_SSH_CLONE_URL,
        });
        expect(findCodeDropdownCloneItemAtIndex(1).props('tracking')).toMatchObject({
          action: COPY_HTTPS_CLONE_URL,
        });
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

        expect(findCodeDropdownCloneItemAtIndex(1).attributes('label')).toContain('HTTPS');
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
      createComponent({
        xcodeUrl: undefined,
        sshUrl: undefined,
        httpUrl: undefined,
        showWebIdeButton: false,
        isGitpodEnabledForUser: false,
        isGitpodEnabledForInstance: false,
      });
      expect(findCodeDropdownIdeItems().exists()).toBe(false);
    });

    it('renders with correct props', () => {
      createComponent();
      expect(findCodeDropdownIdeItems()).toHaveLength(5);

      mockIdeItems.forEach((item, index) => {
        const ideItem = findCodeDropdownIdeItemAtIndex(index);
        expect(ideItem.props('ideItem')).toMatchObject(item);
      });
    });

    // tests for calling tracking covered in code_dropdown/code_dropdown_ide_item_spec.js
    it('passes tracking to ide dropdown', () => {
      createComponent({
        xcodeUrl: undefined,
        sshUrl,
        httpUrl,
        showWebIdeButton: false,
        isGitpodEnabledForUser: false,
        isGitpodEnabledForInstance: false,
      });

      const vscode = findCodeDropdownIdeItemAtIndex(0).props('ideItem').items;
      const intellij = findCodeDropdownIdeItemAtIndex(1).props('ideItem').items;

      expect(vscode[0]).toMatchObject({ tracking: { action: OPEN_VSCODE_SSH } });
      expect(vscode[1]).toMatchObject({ tracking: { action: OPEN_VSCODE_HTTPS } });
      expect(intellij[0]).toMatchObject({ tracking: { action: OPEN_INTELLIJ_SSH } });
      expect(intellij[1]).toMatchObject({ tracking: { action: OPEN_INTELLIJ_HTTPS } });
    });

    describe('conditional IDE items', () => {
      it.each`
        scenario                        | config                                   | excludedItem
        ${'Web IDE when disabled'}      | ${{ showWebIdeButton: false }}           | ${'Web IDE'}
        ${'Ona when user disabled'}     | ${{ isGitpodEnabledForUser: false }}     | ${'Ona'}
        ${'Ona when instance disabled'} | ${{ isGitpodEnabledForInstance: false }} | ${'Ona'}
      `('should not include $excludedItem in $scenario', ({ config, excludedItem }) => {
        createComponent(config);

        const ideItemTexts = findCodeDropdownIdeItems().wrappers.map(
          (ideItem) => ideItem.props('ideItem').text,
        );

        expect(ideItemTexts).not.toContain(excludedItem);
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
