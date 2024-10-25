import { mount } from '@vue/test-utils';
import { GlTable, GlLink, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import ModelVersionsTable from '~/ml/model_registry/components/model_versions_table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { modelVersionWithCandidateAndAuthor } from '../graphql_mock_data';

describe('ModelVersionsTable', () => {
  let wrapper;

  const items = [modelVersionWithCandidateAndAuthor];

  const createWrapper = (props = {}) => {
    wrapper = mount(ModelVersionsTable, {
      propsData: {
        items,
        ...props,
      },
    });
  };

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findGlTable().findAll('tbody tr');

  beforeEach(() => {
    createWrapper();
  });

  it('renders the table', () => {
    expect(findGlTable().exists()).toBe(true);
  });

  it('has the correct columns in the table', () => {
    expect(findGlTable().props('fields')).toEqual([
      { key: 'version', label: 'Version', thClass: 'gl-w-1/3' },
      { key: 'createdAt', label: 'Created', thClass: 'gl-w-1/3' },
      { key: 'author', label: 'Created by' },
    ]);
  });

  it('renders the correct number of rows', () => {
    expect(findTableRows().length).toBe(1);
  });

  it('renders the version link correctly', () => {
    const versionLink = findTableRows().at(0).findComponent(GlLink);
    expect(versionLink.attributes('href')).toBe(items[0]._links.showPath);
    expect(versionLink.text()).toBe(items[0].version);
  });

  it('renders the createdAt tooltip correctly', () => {
    const timeAgoTooltip = findTableRows().at(0).findComponent(TimeAgoTooltip);
    expect(timeAgoTooltip.props('time')).toBe(items[0].createdAt);
  });

  it('renders the author information correctly', () => {
    const avatarLink = findTableRows().at(0).findComponent(GlAvatarLink);
    expect(avatarLink.attributes('href')).toBe(items[0].author.webUrl);
    expect(avatarLink.attributes('title')).toBe(items[0].author.name);

    const avatar = avatarLink.findComponent(GlAvatar);
    expect(avatar.props('src')).toBe(items[0].author.avatarUrl);
    expect(avatarLink.text()).toContain(items[0].author.name);
  });
});
