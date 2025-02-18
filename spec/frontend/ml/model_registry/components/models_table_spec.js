import { mount } from '@vue/test-utils';
import { GlTable, GlLink, GlAvatarLink, GlAvatar, GlDisclosureDropdown } from '@gitlab/ui';
import ModelsTable from '~/ml/model_registry/components/models_table.vue';
import DeleteModelDisclosureDropdownItem from '~/ml/model_registry/components/delete_model_disclosure_dropdown_item.vue';
import { modelWithOneVersion, modelWithoutVersion } from '../graphql_mock_data';

describe('ModelsTable', () => {
  let wrapper;

  const items = [modelWithOneVersion];

  const createWrapper = (props = {}, canWriteModelRegistry = true) => {
    wrapper = mount(ModelsTable, {
      propsData: {
        items,
        ...props,
      },
      stubs: {
        GlTable,
        GlLink,
        GlAvatarLink,
        GlAvatar,
        DeleteModelDisclosureDropdownItem,
      },
      provide: {
        projectPath: 'projectPath',
        canWriteModelRegistry,
      },
    });
  };

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findGlTable().findAll('tbody tr');
  const findActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  beforeEach(() => {
    createWrapper();
  });

  it('renders the table', () => {
    expect(findGlTable().exists()).toBe(true);
  });

  it('has the correct columns in the table', () => {
    expect(findGlTable().props('fields')).toEqual([
      { key: 'name', label: 'Model name', thClass: 'gl-w-1/4' },
      { key: 'latestVersion', label: 'Latest version', thClass: 'gl-w-1/4' },
      { key: 'author', label: 'Author', thClass: 'gl-w-1/4' },
      { key: 'createdAt', label: 'Created', thClass: 'gl-w-1/4' },
      {
        key: 'actions',
        label: '',
        tdClass: 'lg:gl-w-px gl-whitespace-nowrap !gl-p-3 gl-text-right',
        thClass: 'lg:gl-w-px gl-whitespace-nowrap',
      },
    ]);
  });

  it('renders actions dropdown if canWriteModelRegistry is true', () => {
    expect(findActionsDropdown().exists()).toBe(true);
  });

  it('renders the correct number of rows', () => {
    expect(findTableRows().length).toBe(1);
  });

  it('renders the model name link correctly', () => {
    const nameLink = findTableRows().at(0).findComponent(GlLink);
    expect(nameLink.attributes('href')).toBe(items[0]._links.showPath);
    expect(nameLink.text()).toBe(items[0].name);
  });

  it('renders the latest version information correctly', () => {
    const versionCell = findTableRows().at(0).findAll('td').at(1);
    const versionLink = versionCell.findComponent(GlLink);
    expect(versionLink.attributes('href')).toBe(items[0].latestVersion._links.showPath);
    expect(versionLink.text()).toBe(items[0].latestVersion.version);
    expect(versionCell.text().replace(/\s+/g, ' ').trim()).toContain(
      `${items[0].latestVersion.version} · ${items[0].versionCount} version`,
    );
  });

  it('renders the created date correctly', () => {
    const createdAtCell = findTableRows().at(0).findAll('td').at(3);
    expect(createdAtCell.text()).toBe('in 3 years');
  });

  it('renders the author information correctly', () => {
    const avatarLink = findTableRows().at(0).findComponent(GlAvatarLink);
    expect(avatarLink.attributes('href')).toBe(items[0].author.webUrl);
    expect(avatarLink.attributes('title')).toBe(items[0].author.name);

    const avatar = avatarLink.findComponent(GlAvatar);
    expect(avatar.props('src')).toBe(items[0].author.avatarUrl);
    expect(avatar.props('entityName')).toContain(items[0].author.name);
  });

  describe('when the model has no author', () => {
    beforeEach(() => {
      createWrapper({ items: [{ ...modelWithOneVersion, author: null }] });
    });

    it('renders the author information as "Unknown"', () => {
      const authorCell = findTableRows().at(0).findAll('td').at(2);
      expect(authorCell.text()).toBe('');
    });

    it('does not render the author avatar', () => {
      const avatarLink = findTableRows().at(0).findComponent(GlAvatarLink);
      expect(avatarLink.exists()).toBe(false);
    });
  });

  describe('when the model has no latest version', () => {
    beforeEach(() => {
      createWrapper({ items: [{ ...modelWithoutVersion }] });
    });

    it('renders the latest version information as "0 version"', () => {
      const versionCell = findTableRows().at(0).findAll('td').at(1);
      expect(versionCell.text()).toBe('0 versions');
    });
  });

  describe('when the model has no created date', () => {
    beforeEach(() => {
      createWrapper({ items: [{ ...modelWithOneVersion, createdAt: null }] });
    });

    it('renders the created date as "Unknown"', () => {
      const createdAtCell = findTableRows().at(0).findAll('td').at(3);
      expect(createdAtCell.text()).toBe('');
    });
  });

  describe('when the user cannot write to the model registry', () => {
    beforeEach(() => {
      createWrapper({}, false);
    });

    it('does not render actions if canWriteModelRegistry is false', () => {
      expect(findActionsDropdown().exists()).toBe(false);
    });
  });
});
