import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BoardView from '~/work_items/board/board_view.vue';
import ColumnGroup from '~/work_items/board/components/column_group.vue';
import { groupingStrategyFor } from '~/work_items/board/grouping';
import { buildNamespaceStatusesResponse, buildWorkItemTypesResponse } from './mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('BoardView', () => {
  let wrapper;

  const groupByValuesHandler = jest.fn();
  const gateDataHandler = jest.fn();
  // The column-values and gate queries differ by edition (a placeholder in CE,
  // the status queries in EE), so take them from the strategy the board actually uses.
  const { valuesQuery: groupByValuesQuery, gateQuery } = groupingStrategyFor('status');

  const queryVariables = { state: 'opened', sort: 'CREATED_DESC' };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findColumnGroups = () => wrapper.findAllComponents(ColumnGroup);

  const createComponent = ({ props = {} } = {}) => {
    const apolloProvider = createMockApollo([
      [groupByValuesQuery, groupByValuesHandler],
      ...(gateQuery ? [[gateQuery, gateDataHandler]] : []),
    ]);

    wrapper = shallowMountExtended(BoardView, {
      apolloProvider,
      propsData: {
        rootPageFullPath: 'full/path',
        queryVariables,
        ...props,
      },
    });
  };

  beforeEach(() => {
    groupByValuesHandler.mockResolvedValue(buildNamespaceStatusesResponse([]));
    gateDataHandler.mockResolvedValue(buildWorkItemTypesResponse());
  });

  // Statuses are an EE-only field, so grouping by status produces no columns in
  // CE (the placeholder strategy extracts none), and the board degrades
  // gracefully.
  describe('grouping by status', () => {
    it('renders no column groups', async () => {
      createComponent();
      await waitForPromises();

      expect(findColumnGroups()).toHaveLength(0);
    });

    it('renders no loading icon once settled', async () => {
      createComponent();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('reports no error', async () => {
      createComponent();
      await waitForPromises();

      expect(Sentry.captureException).not.toHaveBeenCalled();
      expect(wrapper.emitted('set-error')).toBeUndefined();
    });
  });

  describe('visibleGroups prop', () => {
    it('defaults to null (all groups visible)', () => {
      createComponent();

      expect(wrapper.props('visibleGroups')).toBeNull();
    });

    it('accepts an array without error', async () => {
      createComponent({ props: { visibleGroups: [] } });
      await waitForPromises();

      expect(Sentry.captureException).not.toHaveBeenCalled();
      expect(findColumnGroups()).toHaveLength(0);
    });
  });
});
