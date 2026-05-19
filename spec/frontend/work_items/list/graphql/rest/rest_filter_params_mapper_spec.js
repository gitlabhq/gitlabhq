import { convertGraphQLVarsToRestParams } from '~/work_items/list/graphql/rest/rest_filter_params_mapper';

describe('convertGraphQLVarsToRestParams', () => {
  describe('state', () => {
    it.each([
      ['OPENED', 'opened'],
      ['CLOSED', 'closed'],
      ['ALL', 'all'],
    ])('maps %s to %s', (input, expected) => {
      expect(convertGraphQLVarsToRestParams({ state: input }).get('state')).toBe(expected);
    });

    it('omits state when not provided', () => {
      expect(convertGraphQLVarsToRestParams({}).get('state')).toBeNull();
    });
  });

  describe('sort', () => {
    it.each([
      ['CREATED_ASC', 'created_at', 'asc'],
      ['CREATED_DESC', 'created_at', 'desc'],
      ['UPDATED_ASC', 'updated_at', 'asc'],
      ['UPDATED_DESC', 'updated_at', 'desc'],
      ['TITLE_ASC', 'title', 'asc'],
      ['TITLE_DESC', 'title', 'desc'],
      ['PRIORITY_ASC', 'priority', 'asc'],
      ['PRIORITY_DESC', 'priority', 'desc'],
      ['POPULARITY_ASC', 'upvotes', 'asc'],
      ['POPULARITY_DESC', 'upvotes', 'desc'],
      ['CLOSED_AT_ASC', 'closed_at', 'asc'],
      ['CLOSED_AT_DESC', 'closed_at', 'desc'],
      ['RELATIVE_POSITION_ASC', 'relative_position', 'asc'],
    ])('maps %s to order_by=%s sort=%s', (input, orderBy, sort) => {
      const params = convertGraphQLVarsToRestParams({ sort: input });

      expect(params.get('order_by')).toBe(orderBy);
      expect(params.get('sort')).toBe(sort);
    });

    it('omits sort params for unknown sort value', () => {
      const params = convertGraphQLVarsToRestParams({ sort: 'UNKNOWN_SORT' });

      expect(params.get('order_by')).toBeNull();
      expect(params.get('sort')).toBeNull();
    });

    it('omits sort when not provided', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect(params.get('order_by')).toBeNull();
    });
  });

  describe('pagination', () => {
    it('maps after/first to cursor/per_page', () => {
      const params = convertGraphQLVarsToRestParams({ after: 'abc123', first: 25 });

      expect(params.get('cursor')).toBe('abc123');
      expect(params.get('per_page')).toBe('25');
    });

    it('uses afterCursor as fallback for cursor', () => {
      const params = convertGraphQLVarsToRestParams({ afterCursor: 'cursor1' });

      expect(params.get('cursor')).toBe('cursor1');
    });

    it('uses firstPageSize as fallback for per_page', () => {
      const params = convertGraphQLVarsToRestParams({ firstPageSize: 20 });

      expect(params.get('per_page')).toBe('20');
    });

    it('omits cursor/per_page when not provided', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect(params.get('cursor')).toBeNull();
      expect(params.get('per_page')).toBeNull();
    });
  });

  describe('search', () => {
    it('maps search', () => {
      expect(convertGraphQLVarsToRestParams({ search: 'foo bar' }).get('search')).toBe('foo bar');
    });

    it('omits search when not provided', () => {
      expect(convertGraphQLVarsToRestParams({}).get('search')).toBeNull();
    });
  });

  describe('search within (in parameter)', () => {
    it('maps TITLE to lowercase title', () => {
      const params = convertGraphQLVarsToRestParams({ in: 'TITLE' });

      expect(params.get('in')).toBe('title');
    });

    it('maps DESCRIPTION to lowercase description', () => {
      const params = convertGraphQLVarsToRestParams({ in: 'DESCRIPTION' });

      expect(params.get('in')).toBe('description');
    });

    it('handles lowercase values by converting to lowercase', () => {
      const params = convertGraphQLVarsToRestParams({ in: 'title' });

      expect(params.get('in')).toBe('title');
    });

    it('does not add in parameter when not provided', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect(params.has('in')).toBe(false);
    });
  });

  describe('filters', () => {
    it.each([
      ['authorUsername', 'author_username', 'root'],
      ['subscribed', 'subscribed', 'true'],
      ['crmContactId', 'crm_contact_id', '42'],
      ['crmOrganizationId', 'crm_organization_id', '7'],
    ])('%s → %s', (jsKey, restKey, value) => {
      expect(convertGraphQLVarsToRestParams({ [jsKey]: value }).get(restKey)).toBe(value);
    });

    describe('wildcard filters', () => {
      it.each([
        {
          jsKey: 'assigneeWildcardId',
          restKey: 'assignee_wildcard_id',
          input: 'ANY',
          expected: 'Any',
        },
        {
          jsKey: 'assigneeWildcardId',
          restKey: 'assignee_wildcard_id',
          input: 'NONE',
          expected: 'None',
        },
        {
          jsKey: 'milestoneWildcardId',
          restKey: 'milestone_wildcard_id',
          input: 'ANY',
          expected: 'Any',
        },
        {
          jsKey: 'milestoneWildcardId',
          restKey: 'milestone_wildcard_id',
          input: 'NONE',
          expected: 'None',
        },
        {
          jsKey: 'milestoneWildcardId',
          restKey: 'milestone_wildcard_id',
          input: 'UPCOMING',
          expected: 'Upcoming',
        },
        {
          jsKey: 'milestoneWildcardId',
          restKey: 'milestone_wildcard_id',
          input: 'STARTED',
          expected: 'Started',
        },
        {
          jsKey: 'releaseTagWildcardId',
          restKey: 'release_tag_wildcard_id',
          input: 'ANY',
          expected: 'Any',
        },
        {
          jsKey: 'releaseTagWildcardId',
          restKey: 'release_tag_wildcard_id',
          input: 'NONE',
          expected: 'None',
        },
      ])('$jsKey=$input maps to $restKey=$expected', ({ jsKey, restKey, input, expected }) => {
        expect(convertGraphQLVarsToRestParams({ [jsKey]: input }).get(restKey)).toBe(expected);
      });
    });

    it('maps confidential when true', () => {
      expect(convertGraphQLVarsToRestParams({ confidential: true }).get('confidential')).toBe(
        'true',
      );
    });

    it('maps confidential when false', () => {
      expect(convertGraphQLVarsToRestParams({ confidential: false }).get('confidential')).toBe(
        'false',
      );
    });

    it('omits confidential when undefined', () => {
      expect(convertGraphQLVarsToRestParams({}).get('confidential')).toBeNull();
    });
  });

  describe('array filters', () => {
    it('maps assigneeUsernames as repeated params with [] suffix', () => {
      const params = convertGraphQLVarsToRestParams({ assigneeUsernames: ['alice', 'bob'] });

      expect(params.getAll('assignee_usernames[]')).toEqual(['alice', 'bob']);
    });

    it('maps labelName as repeated params with [] suffix', () => {
      const params = convertGraphQLVarsToRestParams({ labelName: ['bug', 'feature'] });

      expect(params.getAll('label_name[]')).toEqual(['bug', 'feature']);
    });

    it('maps milestoneTitle as repeated params with [] suffix', () => {
      const params = convertGraphQLVarsToRestParams({ milestoneTitle: ['v1.0'] });

      expect(params.getAll('milestone_title[]')).toEqual(['v1.0']);
    });

    it('maps types as lowercase repeated params with [] suffix', () => {
      const params = convertGraphQLVarsToRestParams({ types: ['ISSUE', 'TASK'] });

      expect(params.getAll('types[]')).toEqual(['issue', 'task']);
    });

    it('maps types when provided as a string scalar instead of array', () => {
      const params = convertGraphQLVarsToRestParams({ types: 'ISSUE' });

      expect(params.getAll('types[]')).toEqual(['issue']);
    });

    it('maps releaseTag as repeated params with [] suffix', () => {
      const params = convertGraphQLVarsToRestParams({ releaseTag: ['v1.0', 'v2.0'] });

      expect(params.getAll('release_tag[]')).toEqual(['v1.0', 'v2.0']);
    });
  });

  describe('date filters', () => {
    it.each([
      ['createdAfter', 'created_after'],
      ['createdBefore', 'created_before'],
      ['updatedAfter', 'updated_after'],
      ['updatedBefore', 'updated_before'],
      ['closedAfter', 'closed_after'],
      ['closedBefore', 'closed_before'],
      ['dueAfter', 'due_after'],
      ['dueBefore', 'due_before'],
    ])('maps %s to %s', (jsKey, restKey) => {
      const value = '2024-01-01';

      expect(convertGraphQLVarsToRestParams({ [jsKey]: value }).get(restKey)).toBe(value);
    });
  });

  describe('hierarchy filters', () => {
    it('maps hierarchyFilters.parentId to parent_ids[]', () => {
      const params = convertGraphQLVarsToRestParams({ hierarchyFilters: { parentId: '123' } });

      expect(params.getAll('parent_ids[]')).toEqual(['123']);
    });

    it('maps includeDescendants', () => {
      const params = convertGraphQLVarsToRestParams({ includeDescendants: true });

      expect(params.get('include_descendants')).toBe('true');
    });

    it('omits hierarchy params when not provided', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect(params.getAll('parent_ids[]')).toEqual([]);
      expect(params.get('include_descendants')).toBeNull();
    });
  });

  describe('negated filters (not)', () => {
    it('maps not[scalar] correctly', () => {
      const params = convertGraphQLVarsToRestParams({ not: { authorUsername: 'root' } });

      expect(params.get('not[author_username]')).toBe('root');
    });

    it('maps not[array] as repeated bracket params', () => {
      const params = convertGraphQLVarsToRestParams({ not: { labelName: ['bug', 'wontfix'] } });

      expect(params.getAll('not[label_name][]')).toEqual(['bug', 'wontfix']);
    });

    it('skips null values within not', () => {
      const params = convertGraphQLVarsToRestParams({ not: { authorUsername: null } });

      expect(params.get('not[author_username]')).toBeNull();
    });

    it('does nothing for empty not object', () => {
      const params = convertGraphQLVarsToRestParams({ not: {} });
      const keys = [...params.keys()];

      expect(keys.some((k) => k.startsWith('not['))).toBe(false);
    });
  });

  describe('OR filters (or)', () => {
    it('maps or[scalar] correctly', () => {
      const params = convertGraphQLVarsToRestParams({ or: { authorUsername: 'alice' } });

      expect(params.get('or[author_username]')).toBe('alice');
    });

    it('maps or[array] as repeated bracket params', () => {
      const params = convertGraphQLVarsToRestParams({
        or: { assigneeUsernames: ['alice', 'bob'] },
      });

      expect(params.getAll('or[assignee_usernames][]')).toEqual(['alice', 'bob']);
    });

    it('does nothing for empty or object', () => {
      const params = convertGraphQLVarsToRestParams({ or: {} });
      const keys = [...params.keys()];

      expect(keys.some((k) => k.startsWith('or['))).toBe(false);
    });
  });

  describe('null/undefined handling', () => {
    it('produces no params for an empty vars object', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect([...params.keys()]).toEqual([]);
    });

    it('omits params whose value is null', () => {
      const params = convertGraphQLVarsToRestParams({ search: null, authorUsername: null });

      expect(params.get('search')).toBeNull();
      expect(params.get('author_username')).toBeNull();
    });

    it('omits params whose value is undefined', () => {
      const params = convertGraphQLVarsToRestParams({ search: undefined });

      expect(params.get('search')).toBeNull();
    });
  });
});
