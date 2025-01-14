import { mount } from '@vue/test-utils';
import { GlTableLite, GlBadge, GlLink, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import CandidatesTable from '~/ml/model_registry/components/candidates_table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { graphqlCandidates } from '../graphql_mock_data';

describe('CandidatesTable', () => {
  let wrapper;
  const createWrapper = (props = {}) => {
    wrapper = mount(CandidatesTable, {
      propsData: {
        items: graphqlCandidates,
        ...props,
      },
      stubs: {
        GlTableLite,
        GlBadge,
        GlLink,
        TimeAgoTooltip,
      },
    });
  };

  const findGlTable = () => wrapper.findComponent(GlTableLite);
  const findTableRows = () => wrapper.findAll('tbody tr');

  beforeEach(() => {
    createWrapper();
  });

  it('renders the table', () => {
    expect(findGlTable().exists()).toBe(true);
  });

  it('has the correct columns in the table', () => {
    expect(findGlTable().props('fields')).toEqual([
      { key: 'eid', label: 'MLflow Run ID', thClass: 'gl-w-2/8' },
      { key: 'ciJob', label: 'CI Job', thClass: 'gl-w-1/8' },
      { key: 'createdAt', label: 'Created', thClass: 'gl-w-1/8' },
      { key: 'creator', label: 'Created by', thClass: 'gl-w-2/8' },
      { key: 'status', label: 'Status', thClass: 'gl-w-1/8' },
    ]);
  });

  it('renders the correct number of rows', () => {
    expect(findTableRows().length).toBe(2);
  });

  it('renders the correct information in the id column', () => {
    const idCell = findTableRows().at(0).findAll('td').at(0);
    expect(idCell.text()).toBe(graphqlCandidates[0].eid);
    expect(idCell.findComponent(GlLink).attributes('href')).toBe(
      graphqlCandidates[0]._links.showPath,
    );
  });

  it('renders the correct information in the CI job column', () => {
    const ciJobCell = findTableRows().at(0).findAll('td').at(1);
    expect(ciJobCell.text()).toContain(graphqlCandidates[0].ciJob.name);
    expect(ciJobCell.findComponent(GlLink).attributes('href')).toBe('/path/to/candidate/1');
  });

  it('renders the correct information in the created column', () => {
    const createdAtCell = findTableRows().at(0).findAll('td').at(2);
    expect(createdAtCell.findComponent(TimeAgoTooltip).props('time')).toBe(
      graphqlCandidates[0].createdAt,
    );
  });

  it('renders the author information correctly', () => {
    const authorCell = findTableRows().at(0).findAll('td').at(3);
    const avatarLink = authorCell.findComponent(GlAvatarLink);
    expect(avatarLink.attributes('href')).toBe(graphqlCandidates[0].creator.webUrl);
    expect(avatarLink.attributes('title')).toBe(graphqlCandidates[0].creator.name);

    const avatar = avatarLink.findComponent(GlAvatar);
    expect(avatar.props('src')).toBe(graphqlCandidates[0].creator.avatarUrl);
    expect(avatar.props('size')).toBe(16);
    expect(avatar.props('entityName')).toBe(graphqlCandidates[0].creator.name);

    expect(authorCell.text()).toContain(graphqlCandidates[0].creator.name);
  });

  it('renders the author information correctly for items with no author', () => {
    createWrapper({ items: [{ ...graphqlCandidates[0], creator: null }] });
    const authorCell = findTableRows().at(0).findAll('td').at(3);
    expect(authorCell.findComponent(GlAvatarLink).exists()).toBe(false);
    expect(authorCell.findComponent(GlLink).exists()).toBe(false);
    expect(authorCell.findComponent(GlAvatar).exists()).toBe(false);
    expect(authorCell.text()).toBe('');
  });

  it('renders the correct information in the status column', () => {
    const statusCell = findTableRows().at(0).findAll('td').at(4);
    expect(statusCell.text()).toContain(graphqlCandidates[0].status);
    expect(statusCell.findComponent(GlBadge).props('variant')).toBe('info');
  });

  describe('when there is no CI Job information', () => {
    beforeEach(() => {
      createWrapper({ items: [{ ...graphqlCandidates[0], ciJob: null }] });
    });

    it('does not render content in CI Job column', () => {
      const ciJobCell = findTableRows().at(0).findAll('td').at(1);
      expect(ciJobCell.text()).toBe('');
    });

    it('does not render a link in the CI Job column', () => {
      const ciJobCell = findTableRows().at(0).findAll('td').at(1);
      expect(ciJobCell.findComponent(GlLink).exists()).toBe(false);
    });
  });
});
