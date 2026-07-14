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
      ['POPULARITY_ASC', 'popularity', 'asc'],
      ['POPULARITY_DESC', 'popularity', 'desc'],
      ['CLOSED_AT_ASC', 'closed_at', 'asc'],
      ['CLOSED_AT_DESC', 'closed_at', 'desc'],
      ['RELATIVE_POSITION_ASC', 'relative_position', 'asc'],
      ['LABEL_PRIORITY_ASC', 'label_priority', 'asc'],
      ['LABEL_PRIORITY_DESC', 'label_priority', 'desc'],
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
    describe('keyset pagination (cursor-based)', () => {
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

      it('maps before/last to cursor/per_page for previous page', () => {
        const params = convertGraphQLVarsToRestParams({ before: 'prev123', last: 10 });

        expect(params.get('cursor')).toBe('prev123');
        expect(params.get('per_page')).toBe('10');
      });

      it('uses beforeCursor as fallback for cursor', () => {
        const params = convertGraphQLVarsToRestParams({ beforeCursor: 'cursor2' });

        expect(params.get('cursor')).toBe('cursor2');
      });

      it('uses lastPageSize as fallback for per_page', () => {
        const params = convertGraphQLVarsToRestParams({ lastPageSize: 15 });

        expect(params.get('per_page')).toBe('15');
      });

      it('prefers afterCursor over beforeCursor when both present', () => {
        const params = convertGraphQLVarsToRestParams({
          afterCursor: 'next1',
          beforeCursor: 'prev1',
        });

        expect(params.get('cursor')).toBe('next1');
      });

      it('uses cursor parameter for alphanumeric cursor values', () => {
        const params = convertGraphQLVarsToRestParams({ after: 'abc123def' });

        expect(params.get('cursor')).toBe('abc123def');
        expect(params.get('page')).toBeNull();
      });
    });

    describe('offset pagination (page-based)', () => {
      it('maps numeric cursor value to page parameter', () => {
        const params = convertGraphQLVarsToRestParams({ after: '2', first: 20 });

        expect(params.get('page')).toBe('2');
        expect(params.get('cursor')).toBeNull();
        expect(params.get('per_page')).toBe('20');
      });

      it('maps numeric afterCursor to page parameter', () => {
        const params = convertGraphQLVarsToRestParams({ afterCursor: '3' });

        expect(params.get('page')).toBe('3');
        expect(params.get('cursor')).toBeNull();
      });

      it('maps numeric beforeCursor to page parameter', () => {
        const params = convertGraphQLVarsToRestParams({ beforeCursor: '1' });

        expect(params.get('page')).toBe('1');
        expect(params.get('cursor')).toBeNull();
      });
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
          jsKey: 'assigneeWildcardId',
          restKey: 'assignee_wildcard_id',
          input: 'ME',
          expected: 'Me',
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

    it('maps workItemTypeIds as work_item_type_ids[] with numeric IDs extracted from GIDs', () => {
      const params = convertGraphQLVarsToRestParams({
        workItemTypeIds: ['gid://gitlab/WorkItems::Type/1', 'gid://gitlab/WorkItems::Type/2'],
      });

      expect(params.getAll('work_item_type_ids[]')).toEqual(['1', '2']);
    });

    it('maps workItemTypeIds when provided as a single GID instead of array', () => {
      const params = convertGraphQLVarsToRestParams({
        workItemTypeIds: 'gid://gitlab/WorkItems::Type/1',
      });

      expect(params.getAll('work_item_type_ids[]')).toEqual(['1']);
    });

    it('omits work_item_type_ids[] when workItemTypeIds is not provided', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect(params.getAll('work_item_type_ids[]')).toEqual([]);
    });

    it('maps not.workItemTypeIds as not[work_item_type_ids][] with numeric IDs', () => {
      const params = convertGraphQLVarsToRestParams({
        not: { workItemTypeIds: ['gid://gitlab/WorkItems::Type/1'] },
      });

      expect(params.getAll('not[work_item_type_ids][]')).toEqual(['1']);
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
    it('maps hierarchyFilters.parentIds to parent_ids[] with numeric IDs', () => {
      const params = convertGraphQLVarsToRestParams({
        hierarchyFilters: { parentIds: ['gid://gitlab/WorkItem/123'] },
      });

      expect(params.getAll('parent_ids[]')).toEqual(['123']);
    });

    it('maps hierarchyFilters.parentWildcardId to parent_wildcard_id', () => {
      const params = convertGraphQLVarsToRestParams({
        hierarchyFilters: { parentWildcardId: 'ANY' },
      });

      expect(params.get('parent_wildcard_id')).toBe('Any');
    });

    it('maps hierarchyFilters.parentWildcardId NONE', () => {
      const params = convertGraphQLVarsToRestParams({
        hierarchyFilters: { parentWildcardId: 'NONE' },
      });

      expect(params.get('parent_wildcard_id')).toBe('None');
    });

    it('maps hierarchyFilters.includeDescendantWorkItems', () => {
      const params = convertGraphQLVarsToRestParams({
        hierarchyFilters: { includeDescendantWorkItems: true },
      });

      expect(params.get('include_descendant_work_items')).toBe('true');
    });

    it('maps includeDescendants', () => {
      const params = convertGraphQLVarsToRestParams({ includeDescendants: true });

      expect(params.get('include_descendants')).toBe('true');
    });

    it('omits hierarchy params when not provided', () => {
      const params = convertGraphQLVarsToRestParams({});

      expect(params.getAll('parent_ids[]')).toEqual([]);
      expect(params.get('parent_wildcard_id')).toBeNull();
      expect(params.get('include_descendant_work_items')).toBeNull();
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

    it('maps not[parentIds] with numeric IDs extracted from GIDs', () => {
      const params = convertGraphQLVarsToRestParams({
        not: { parentIds: ['gid://gitlab/WorkItem/456'] },
      });

      expect(params.getAll('not[parent_ids][]')).toEqual(['456']);
    });

    it('maps not[milestoneWildcardId] to capitalized format', () => {
      const params = convertGraphQLVarsToRestParams({
        not: { milestoneWildcardId: 'UPCOMING' },
      });

      expect(params.get('not[milestone_wildcard_id]')).toBe('Upcoming');
    });

    it('maps not[milestoneWildcardId] STARTED to capitalized format', () => {
      const params = convertGraphQLVarsToRestParams({
        not: { milestoneWildcardId: 'STARTED' },
      });

      expect(params.get('not[milestone_wildcard_id]')).toBe('Started');
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
