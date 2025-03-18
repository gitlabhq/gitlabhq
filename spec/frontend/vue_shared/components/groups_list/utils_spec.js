import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import { deleteParams, renderDeleteSuccessToast } from '~/vue_shared/components/groups_list/utils';
import { formatGroups } from '~/organizations/shared/utils';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const {
  data: {
    organization: {
      groups: { nodes: groups },
    },
  },
} = organizationGroupsGraphQlResponse;

describe('renderDeleteSuccessToast', () => {
  const [MOCK_GROUP] = formatGroups(groups);

  it('calls toast correctly', () => {
    renderDeleteSuccessToast(MOCK_GROUP);

    expect(toast).toHaveBeenCalledWith(`Group '${MOCK_GROUP.fullName}' is being deleted.`);
  });
});

describe('deleteParams', () => {
  it('returns {} always', () => {
    expect(deleteParams()).toStrictEqual({});
  });
});
