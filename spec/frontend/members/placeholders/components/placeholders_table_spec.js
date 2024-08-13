import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { mount, shallowMount } from '@vue/test-utils';
import { GlAvatarLabeled, GlBadge, GlKeysetPagination, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';

import PlaceholdersTable from '~/members/placeholders/components/placeholders_table.vue';
import PlaceholderActions from '~/members/placeholders/components/placeholder_actions.vue';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';

import {
  PLACEHOLDER_STATUS_FAILED,
  QUERY_PARAM_FAILED,
  PLACEHOLDER_USER_STATUS,
} from '~/import_entities/import_groups/constants';

import importSourceUsersQuery from '~/members/placeholders/graphql/queries/import_source_users.query.graphql';
import { mockSourceUsersQueryResponse, mockSourceUsers } from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);
jest.mock('~/alert');

describe('PlaceholdersTable', () => {
  let wrapper;
  let mockApollo;

  const mockGroup = {
    path: 'imported-group',
    name: 'Imported group',
  };

  const defaultProps = {
    queryStatuses: PLACEHOLDER_USER_STATUS.UNASSIGNED,
    reassigned: false,
  };

  const sourceUsersQueryHandler = jest.fn().mockResolvedValue(mockSourceUsersQueryResponse());
  const $toast = {
    show: jest.fn(),
  };

  const createComponent = ({
    mountFn = shallowMount,
    queryHandler = sourceUsersQueryHandler,
    props = {},
    options = {},
  } = {}) => {
    mockApollo = createMockApollo([[importSourceUsersQuery, queryHandler]]);

    wrapper = mountFn(PlaceholdersTable, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        group: mockGroup,
      },
      mocks: { $toast },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      ...options,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findTableFields = () =>
    findTable()
      .props('fields')
      .map((f) => f.label);

  describe('when sourceUsers query is loading', () => {
    it('renders table as loading', () => {
      createComponent();
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when sourceUsers query fails', () => {
    beforeEach(async () => {
      const sourceUsersFailedQueryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      createComponent({
        queryHandler: sourceUsersFailedQueryHandler,
      });
      await waitForPromises();
    });

    it('creates an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching placeholder users.',
      });
    });
  });

  describe('when sourceUsers query succeeds', () => {
    beforeEach(async () => {
      createComponent({
        mountFn: mount,
      });
      await waitForPromises();
    });

    it('fetches sourceUsers', () => {
      expect(sourceUsersQueryHandler).toHaveBeenCalledTimes(1);
      expect(sourceUsersQueryHandler).toHaveBeenCalledWith({
        after: null,
        before: null,
        fullPath: mockGroup.path,
        first: 20,
        statuses: PLACEHOLDER_USER_STATUS.UNASSIGNED,
      });
    });

    it('renders table', async () => {
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTableRows()).toHaveLength(mockSourceUsers.length);

      expect(findTableFields()).toEqual([
        'Placeholder user',
        'Source',
        'Reassignment status',
        'Reassign placeholder to',
      ]);
    });

    it('renders avatar for placeholder user', async () => {
      await waitForPromises();

      const avatar = findTableRows().at(0).findComponent(GlAvatarLabeled);
      const { placeholderUser } = mockSourceUsers[0];

      expect(avatar.props()).toMatchObject({
        label: placeholderUser.name,
        subLabel: `@${placeholderUser.username}`,
      });
      expect(avatar.attributes('src')).toBe(placeholderUser.avatarUrl);
    });

    it('renders source info', async () => {
      await waitForPromises();

      expect(findTableRows().at(0).text()).toContain(mockSourceUsers[0].sourceHostname);
      expect(findTableRows().at(0).text()).toContain(mockSourceUsers[0].sourceUsername);
    });

    it('renders status badge with tooltip', async () => {
      await waitForPromises();

      const firstRow = findTableRows().at(0);
      const badge = firstRow.findComponent(GlBadge);
      const badgeTooltip = getBinding(badge.element, 'gl-tooltip');

      expect(badge.text()).toBe('Not started');
      expect(badgeTooltip.value).toBe('Reassignment has not started.');
    });

    it('renders avatar for placeholderUser when item status is KEEP_AS_PLACEHOLDER', async () => {
      await waitForPromises();

      const reassignedItemRow = findTableRows().at(5);
      const actionsAvatar = reassignedItemRow.findAllComponents(GlAvatarLabeled).at(1);
      const { placeholderUser } = mockSourceUsers[5];

      expect(actionsAvatar.props()).toMatchObject({
        label: placeholderUser.name,
        subLabel: `@${placeholderUser.username}`,
      });
    });

    it('renders actions when item is not reassigned', async () => {
      await waitForPromises();

      const firstRow = findTableRows().at(0);
      const actions = firstRow.findComponent(PlaceholderActions);

      expect(actions.props('sourceUser')).toEqual(mockSourceUsers[0]);
    });

    it('renders avatar for reassignToUser when item status is COMPLETED', async () => {
      await waitForPromises();

      const reassignedItemRow = findTableRows().at(6);
      const actionsAvatar = reassignedItemRow.findAllComponents(GlAvatarLabeled).at(1);
      const { reassignToUser } = mockSourceUsers[6];

      expect(actionsAvatar.props()).toMatchObject({
        label: reassignToUser.name,
        subLabel: `@${reassignToUser.username}`,
      });
    });

    it('table actions emit "confirm" event with item', () => {
      const actions = findTableRows().at(2).findComponent(PlaceholderActions);

      actions.vm.$emit('confirm');

      expect(wrapper.emitted('confirm')[0]).toEqual([mockSourceUsers[2]]);
    });
  });

  describe('pagination', () => {
    describe.each`
      hasNextPage | hasPreviousPage | expectPagination
      ${false}    | ${false}        | ${false}
      ${false}    | ${true}         | ${true}
      ${true}     | ${false}        | ${true}
      ${true}     | ${true}         | ${true}
    `(
      'when hasNextPage=$hasNextPage and hasPreviousPage=$hasPreviousPage',
      ({ hasNextPage, hasPreviousPage, expectPagination }) => {
        beforeEach(async () => {
          const customHandler = jest.fn().mockResolvedValue(
            mockSourceUsersQueryResponse({
              pageInfo: {
                hasNextPage,
                hasPreviousPage,
              },
            }),
          );
          createComponent({
            queryHandler: customHandler,
          });
          await nextTick();
        });
        it(`${expectPagination ? 'renders' : 'does not render'} pagination`, () => {
          expect(findPagination().exists()).toBe(expectPagination);
        });
      },
    );

    describe('buttons', () => {
      const mockPageInfo = {
        endCursor: 'end834',
        hasNextPage: true,
        hasPreviousPage: true,
        startCursor: 'start971',
      };
      const customHandler = jest.fn().mockResolvedValue(
        mockSourceUsersQueryResponse({
          pageInfo: mockPageInfo,
        }),
      );

      beforeEach(async () => {
        createComponent({
          mountFn: mount,
          queryHandler: customHandler,
        });
        await waitForPromises();
      });

      it('requests the next page on "prev" click with the correct data', async () => {
        const paginated = findPagination();
        await paginated.vm.$emit('prev');
        expect(customHandler).toHaveBeenCalledTimes(2);
        expect(customHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            after: null,
            before: mockPageInfo.startCursor,
            last: 20,
          }),
        );
      });

      it('requests the next page on "next" click the correct data', async () => {
        const paginated = findPagination();
        await paginated.vm.$emit('next');
        expect(customHandler).toHaveBeenCalledTimes(2);
        expect(customHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            after: mockPageInfo.endCursor,
            before: null,
            first: 20,
          }),
        );
      });
    });
  });

  describe('correctly filters users with failed status', () => {
    const sourceUsersFailureQueryHandler = jest
      .fn()
      .mockResolvedValue(mockSourceUsersQueryResponse({ nodes: [mockSourceUsers[4]] }));

    beforeEach(async () => {
      setWindowLocation(`?status=${QUERY_PARAM_FAILED}`);
      await waitForPromises();

      createComponent({
        mountFn: shallowMount,
        queryHandler: sourceUsersFailureQueryHandler,
        props: { queryStatuses: [PLACEHOLDER_STATUS_FAILED] },
        options: {
          stubs: {
            GlTable: stubComponent(GlTable, {
              props: ['fields', 'items', 'busy'],
            }),
          },
        },
      });
      await waitForPromises();
    });

    it('when the url includes the query param failed', () => {
      expect(findTable().props('items')).toHaveLength(1);
      expect(findTable().props('items')[0].status).toBe(PLACEHOLDER_STATUS_FAILED);
      expect(sourceUsersFailureQueryHandler).toHaveBeenCalledTimes(1);
      expect(sourceUsersFailureQueryHandler).toHaveBeenCalledWith({
        after: null,
        before: null,
        fullPath: mockGroup.path,
        first: 20,
        statuses: [PLACEHOLDER_STATUS_FAILED],
      });
    });
  });

  describe('when is "Re-assigned" table variant', () => {
    const reassignedQueryHandler = jest
      .fn()
      .mockResolvedValue(
        mockSourceUsersQueryResponse({ nodes: [mockSourceUsers[5], mockSourceUsers[6]] }),
      );

    beforeEach(async () => {
      createComponent({
        mountFn: shallowMount,
        queryHandler: reassignedQueryHandler,
        props: { reassigned: true, queryStatus: PLACEHOLDER_USER_STATUS.REASSIGNED },
        options: {
          stubs: {
            GlTable: stubComponent(GlTable, {
              props: ['fields', 'items', 'busy'],
            }),
          },
        },
      });

      await waitForPromises();
    });

    it('renders table', () => {
      expect(findTable().exists()).toBe(true);
      expect(findTableFields()).toEqual([
        'Placeholder user',
        'Source',
        'Reassignment status',
        'Reassigned to',
      ]);
    });

    it('only displays items that have been already assigned', () => {
      expect(findTable().props('items')).toEqual([mockSourceUsers[5], mockSourceUsers[6]]);
    });
  });
});
