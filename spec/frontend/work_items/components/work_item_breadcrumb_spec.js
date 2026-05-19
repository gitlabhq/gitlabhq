import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import { STATUS_OPEN } from '~/issues/constants';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { UPDATED_DESC } from '~/work_items/list/constants';
import WorkItemBreadcrumb from '~/work_items/components/work_item_breadcrumb.vue';
import { WORK_ITEM_TYPE_NAME_TICKET, ROUTES } from '~/work_items/constants';
import { setPlanningViewAllItemsFilters } from '~/work_items/pages/planning_view_state';

describe('WorkItemBreadcrumb', () => {
  let wrapper;

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  beforeEach(() => {
    setPlanningViewAllItemsFilters(null);
  });

  const createComponent = ({
    workItemType = null,
    $route = {},
    isGroup = true,
    props = {},
  } = {}) => {
    wrapper = shallowMount(WorkItemBreadcrumb, {
      provide: {
        workItemType,
        isGroup,
      },
      mocks: {
        $route,
      },
      propsData: { staticBreadcrumbs: [], ...props },
    });
  };

  describe('when a session exists', () => {
    it('uses session sortKey and always resets state to open in the index crumb', () => {
      setPlanningViewAllItemsFilters({ sortKey: UPDATED_DESC, state: 'closed', filterTokens: [] });
      createComponent({
        $route: { name: 'workItem', params: { iid: '1', type: 'work_items' }, path: '/1' },
      });

      const indexCrumb = findBreadcrumb()
        .props('items')
        .find((c) => c.to?.name === ROUTES.index);

      expect(indexCrumb.to.query).toEqual({
        sort: 'updated_desc',
        state: STATUS_OPEN,
        first_page_size: DEFAULT_PAGE_SIZE,
      });
    });

    it('uses session filters when navigating from a saved view to All items', () => {
      setPlanningViewAllItemsFilters({
        sortKey: UPDATED_DESC,
        state: STATUS_OPEN,
        filterTokens: [],
      });
      createComponent({
        $route: {
          name: ROUTES.savedView,
          params: { view_id: '123', type: 'work_items' },
          path: '/views/123',
        },
      });

      const indexCrumb = findBreadcrumb()
        .props('items')
        .find((c) => c.to?.name === ROUTES.index);

      expect(indexCrumb.to.query).toEqual({
        sort: 'updated_desc',
        state: STATUS_OPEN,
        first_page_size: DEFAULT_PAGE_SIZE,
      });
    });
  });

  describe('when no session exists', () => {
    it('navigates to All items without query params', () => {
      createComponent({
        $route: {
          name: ROUTES.savedView,
          params: { view_id: '123', type: 'work_items' },
          path: '/views/123',
        },
      });

      const indexCrumb = findBreadcrumb()
        .props('items')
        .find((c) => c.to?.name === ROUTES.index);

      expect(indexCrumb.to.query).toBeUndefined();
    });
  });

  describe('when the workspace is a group', () => {
    it('renders root `Work items` breadcrumb on work items list page', () => {
      createComponent();

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Work items',
          to: {
            name: ROUTES.index,
            query: undefined,
            params: { type: 'work_items' },
          },
        },
      ]);
    });

    it('renders root `Service Desk` breadcrumb on service desk list page', () => {
      createComponent({ workItemType: WORK_ITEM_TYPE_NAME_TICKET });

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Service Desk',
          to: {
            name: ROUTES.index,
            query: undefined,
            params: { type: 'service_desk' },
          },
        },
      ]);
    });
  });

  describe('when the workspace is a project', () => {
    it('renders root `Work items` breadcrumb with router link', () => {
      createComponent({ isGroup: false });

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Work items',
          to: {
            name: ROUTES.index,
            query: undefined,
            params: { type: 'work_items' },
          },
        },
      ]);
    });
  });

  it('renders `New` breadcrumb on new work item page', () => {
    createComponent({ $route: { name: 'new' } });

    expect(findBreadcrumb().props('items')).toEqual(
      expect.arrayContaining([
        { text: 'New', to: { name: 'new', params: { type: 'work_items' } } },
      ]),
    );
  });

  it('combines static and dynamic breadcrumbs', () => {
    createComponent({
      $route: { name: 'workItem', params: { iid: '1', type: 'work_items' }, path: '/1' },
      props: {
        staticBreadcrumbs: [{ text: 'Static', href: '/static' }],
      },
    });

    expect(findBreadcrumb().props('items')).toEqual([
      { text: 'Static', href: '/static' },
      {
        text: 'Work items',
        to: { name: ROUTES.index, query: undefined, params: { type: 'work_items' } },
      },
      { text: '#1', to: { name: 'workItem', params: { type: 'work_items', iid: '1' } } },
    ]);
  });

  it('renders work item iid breadcrumb on work item detail page', () => {
    createComponent({
      $route: { name: 'workItem', params: { iid: '1', type: 'work_items' }, path: '/1' },
    });

    expect(findBreadcrumb().props('items')).toEqual(
      expect.arrayContaining([
        { text: '#1', to: { name: 'workItem', params: { type: 'work_items', iid: '1' } } },
      ]),
    );
  });
});
