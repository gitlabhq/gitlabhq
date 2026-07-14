import { GlLoadingIcon, GlSearchBoxByType, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { groupingStrategyFor } from '~/work_items/board/grouping';
import WorkItemDisplaySettingsGroupBy from '~/work_items/list/components/work_item_display_settings_group_by.vue';
import { buildNamespaceStatusesResponse } from '../../board/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemDisplaySettingsGroupBy', () => {
  let wrapper;

  const statusesQueryHandler = jest.fn();
  // The column-values query differs by edition (a placeholder in CE, the status
  // query in EE), so take it from the strategy the component actually uses.
  const statusesQuery = groupingStrategyFor('status').valuesQuery;

  const findGroupByListbox = () => wrapper.findByTestId('group-by-listbox');
  const findSortListbox = () => wrapper.findByTestId('sort-listbox');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHideAll = () => wrapper.findByTestId('hide-all');
  const findValueRows = () => wrapper.findAllComponents(GlToggle);

  const createComponent = ({ props = {} } = {}) => {
    const apolloProvider = createMockApollo([[statusesQuery, statusesQueryHandler]]);

    wrapper = shallowMountExtended(WorkItemDisplaySettingsGroupBy, {
      apolloProvider,
      propsData: {
        fullPath: 'group/full/path',
        workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
        ...props,
      },
    });
  };

  beforeEach(() => {
    statusesQueryHandler.mockResolvedValue(buildNamespaceStatusesResponse([]));
  });

  it('renders a disabled Group by dropdown showing the current strategy label', () => {
    createComponent();

    const listbox = findGroupByListbox();
    expect(listbox.props()).toMatchObject({
      disabled: true,
      toggleText: 'Status',
      selected: 'status',
    });
  });

  it('renders a disabled Sort dropdown showing Ascending', () => {
    createComponent();

    const listbox = findSortListbox();
    expect(listbox.props()).toMatchObject({
      disabled: true,
      toggleText: 'Ascending',
      selected: 'asc',
    });
  });

  it('renders a disabled search box', () => {
    createComponent();

    expect(findSearchBox().props('disabled')).toBe(true);
  });

  it('renders an enabled Hide all button', async () => {
    createComponent();
    await waitForPromises();

    expect(findHideAll().text()).toBe('Hide all');
    expect(findHideAll().attributes('disabled')).toBeUndefined();
  });

  it('calls the statuses query with fullPath', async () => {
    createComponent({ props: { fullPath: 'group/subgroup' } });
    await waitForPromises();

    expect(statusesQueryHandler).toHaveBeenCalledWith({ fullPath: 'group/subgroup' });
  });

  it('renders the loading icon while the query is in flight', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('hides the loading icon once the query resolves', async () => {
    createComponent();
    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('once the query resolves', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders no value toggles (statuses is an EE-only field)', () => {
      expect(findValueRows()).toHaveLength(0);
    });
  });

  describe('when the statuses query errors', () => {
    const queryError = new Error('GraphQL failure');

    beforeEach(async () => {
      statusesQueryHandler.mockRejectedValue(queryError);
      createComponent();
      await waitForPromises();
    });

    it('shows an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching the groups.',
        captureError: true,
        error: queryError,
      });
    });
  });
});
