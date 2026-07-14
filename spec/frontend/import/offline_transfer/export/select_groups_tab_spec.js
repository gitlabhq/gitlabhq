import { GlLoadingIcon, GlEmptyState, GlKeysetPagination, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SelectGroupsTab from '~/import/offline_transfer/export/select_groups_tab.vue';
import GroupRow from '~/import/offline_transfer/components/group_row.vue';
import { mockGroups } from '../mock_data';

describe('SelectGroupsTab', () => {
  let wrapper;

  const defaultProps = {
    pageGroups: mockGroups,
    showSelectError: false,
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(SelectGroupsTab, {
      propsData: { ...defaultProps, ...propsData },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findList = () => wrapper.find('ul');
  const findAllRows = () => wrapper.findAllComponents(GroupRow);
  const findCount = () => wrapper.findByTestId('selected-count');
  const findSelectCurrentPage = () => wrapper.findByTestId('select-current-page');
  const findDeselectAll = () => wrapper.findByTestId('deselect-all');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNoGroupsSelectedError = () => wrapper.findByTestId('selected-error');
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findResults = () => wrapper.findByTestId('groups-results');

  describe('group list', () => {
    it('shows the empty message when not loading and there are no groups', () => {
      createComponent({ pageGroups: [] });

      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders one GroupRow per group', () => {
      createComponent();

      expect(findAllRows()).toHaveLength(mockGroups.length);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('passes correct props to each row', () => {
      createComponent();
      const firstRow = findAllRows().at(0);

      expect(firstRow.props()).toMatchObject({
        name: 'Flight',
        description: 'Flight',
        avatarUrl: null,
        selectable: true,
      });
    });

    it('marks a row checked when its id is in selectedIds', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'] });

      expect(findAllRows().at(0).props('checked')).toBe(true);
      expect(findAllRows().at(1).props('checked')).toBe(false);
    });
  });

  describe('loading state', () => {
    it('shows the loading spinner only on initial load', () => {
      createComponent({ initialLoading: true, pageGroups: [] });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findList().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show the loading spinner once data has loaded', () => {
      createComponent({ initialLoading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('keeps the list mounted but dimmed while a refetch is loading', () => {
      createComponent({ loading: true });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findList().exists()).toBe(true);
      expect(findResults().classes()).toContain('gl-opacity-5');
    });

    it('does not dim the list once the refetch settles', () => {
      createComponent({ loading: false });

      expect(findResults().classes()).not.toContain('gl-opacity-5');
    });

    it('shows a loading indicator inside the search box while loading', () => {
      createComponent({ loading: true });

      expect(findSearchBox().props('isLoading')).toBe(true);
    });

    it('does not flash the empty state while a search is loading', () => {
      createComponent({ loading: true, pageGroups: [], searchTerm: 'no match' });
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('selection', () => {
    it('count matches the total groups selected', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'] });

      expect(findCount().text()).toBe('1 group selected');
    });

    it('emits toggle with the group when a row is selected', () => {
      createComponent();
      findAllRows().at(1).vm.$emit('toggle');

      expect(wrapper.emitted('toggle')).toEqual([[mockGroups[1]]]);
    });

    it('emits select-current-page when Select all is clicked', () => {
      createComponent();
      findSelectCurrentPage().vm.$emit('click');

      expect(wrapper.emitted('select-current-page')).toHaveLength(1);
    });

    it('emits deselect-all when Deselect all is clicked', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'] });
      findDeselectAll().vm.$emit('click');

      expect(wrapper.emitted('deselect-all')).toHaveLength(1);
    });

    it('disables Select all when every group is already selected', () => {
      createComponent({ selectedIds: mockGroups.map((group) => group.id) });

      expect(findSelectCurrentPage().props('disabled')).toBe(true);
    });

    it('disables Deselect all when nothing is selected', () => {
      createComponent();

      expect(findDeselectAll().props('disabled')).toBe(true);
      expect(findNoGroupsSelectedError().exists()).toBe(false);
    });

    it('error is shown when nothing is selected and showSelectError is passed as true', () => {
      createComponent({ selectedIds: [], showSelectError: true });

      expect(findNoGroupsSelectedError().text()).toBe('Select at least one group to continue');
    });

    it('hides error when a group becomes selected even if showSelectError is true', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'], showSelectError: true });

      expect(findNoGroupsSelectedError().exists()).toBe(false);
      expect(findCount().exists()).toBe(true);
    });
  });

  describe('pagination', () => {
    it('is not rendered when there is just one page', () => {
      createComponent({ pageInfo: { hasNextPage: false, hasPreviousPage: false } });

      expect(findPagination().exists()).toBe(false);
    });

    it('renders when there is a next page', () => {
      createComponent({ pageInfo: { hasNextPage: true, hasPreviousPage: false } });

      expect(findPagination().exists()).toBe(true);
    });

    it('renders when there is a previous page', () => {
      createComponent({ pageInfo: { hasNextPage: false, hasPreviousPage: true } });

      expect(findPagination().exists()).toBe(true);
    });

    it('disables pagination while a refetch is loading', () => {
      createComponent({ loading: true, pageInfo: { hasNextPage: true, hasPreviousPage: true } });

      expect(findPagination().props('disabled')).toBe(true);
    });

    it('correctly emits `next` with the cursor', () => {
      createComponent({ pageInfo: { hasNextPage: true, hasPreviousPage: false } });

      findPagination().vm.$emit('next', 'cursor123');

      expect(wrapper.emitted('next')).toEqual([['cursor123']]);
    });

    it('correctly emits `prev` with the cursor', () => {
      createComponent({ pageInfo: { hasNextPage: false, hasPreviousPage: true } });

      findPagination().vm.$emit('prev', 'cursor456');

      expect(wrapper.emitted('prev')).toEqual([['cursor456']]);
    });
  });

  describe('search', () => {
    it('term is correctly passed to input search box', () => {
      createComponent({ searchTerm: 'flight' });
      expect(findSearchBox().props('value')).toBe('flight');
    });

    it('term is emitted when the search input changes', () => {
      createComponent();
      findSearchBox().vm.$emit('input', 'flight');
      expect(wrapper.emitted('search')).toEqual([['flight']]);
    });
  });

  describe('empty state', () => {
    it('when user owns no groups informs the user that there are no groups', () => {
      createComponent({ pageGroups: [] });
      expect(findEmptyState().props('title')).toBe('You have no groups available to export');
    });

    it('when search does not return a match informs the user there is no match', () => {
      createComponent({ pageGroups: [], searchTerm: 'no match' });

      expect(findEmptyState().props('title')).toBe('No groups match your search');
    });
  });
});
