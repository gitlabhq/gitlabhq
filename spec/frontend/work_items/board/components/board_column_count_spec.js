import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import BoardColumnCount from '~/work_items/board/components/board_column_count.vue';
import { mockStatus, buildBoardWorkItemsCountResponse } from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('BoardColumnCount', () => {
  let wrapper;
  let apolloProvider;

  const countQueryHandler = jest.fn();

  const baseQueryVariables = {
    state: 'opened',
    sort: 'CREATED_DESC',
  };

  // The component only reads `groupFilter` off the strategy, so a small generic
  // fixture stands in for a real (EE-only) grouping strategy.
  const mockStrategy = {
    groupFilter: (value) => ({ status: { name: value.name } }),
  };

  const createComponent = ({ props = {} } = {}) => {
    apolloProvider = createMockApollo([[getWorkItemsCountOnlyQuery, countQueryHandler]]);

    wrapper = shallowMountExtended(BoardColumnCount, {
      apolloProvider,
      propsData: {
        value: mockStatus,
        strategy: mockStrategy,
        rootPageFullPath: 'full/path',
        baseQueryVariables,
        ...props,
      },
    });
  };

  beforeEach(() => {
    countQueryHandler.mockResolvedValue(buildBoardWorkItemsCountResponse(3));
  });

  it('renders nothing', async () => {
    createComponent();
    await waitForPromises();

    expect(wrapper.html()).toBe('');
  });

  it('queries the count with the column query variables', async () => {
    createComponent();
    await waitForPromises();

    expect(countQueryHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        fullPath: 'full/path',
        ...baseQueryVariables,
        status: { name: mockStatus.name },
      }),
    );
  });

  it('emits the count once the query resolves', async () => {
    createComponent();
    await waitForPromises();

    expect(wrapper.emitted('change')).toEqual([[{ valueId: mockStatus.id, count: 3 }]]);
  });

  it('refetches when the query variables change', async () => {
    createComponent();
    await waitForPromises();

    countQueryHandler.mockResolvedValue(buildBoardWorkItemsCountResponse(9));
    await wrapper.setProps({ baseQueryVariables: { ...baseQueryVariables, sort: 'CREATED_ASC' } });
    await waitForPromises();

    expect(countQueryHandler).toHaveBeenCalledTimes(2);
    expect(wrapper.emitted('change')[1]).toEqual([{ valueId: mockStatus.id, count: 9 }]);
  });

  it('emits a null count and captures the error in Sentry when the query fails', async () => {
    const queryError = new Error('GraphQL failure');
    countQueryHandler.mockRejectedValue(queryError);
    createComponent();
    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalledWith(queryError);
    expect(wrapper.emitted('change')).toEqual([[{ valueId: mockStatus.id, count: null }]]);
  });
});
