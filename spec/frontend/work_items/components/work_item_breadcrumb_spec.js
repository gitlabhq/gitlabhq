import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import WorkItemBreadcrumb from '~/work_items/components/work_item_breadcrumb.vue';
import { WORK_ITEM_TYPE_NAME_EPIC } from '~/work_items/constants';

describe('WorkItemBreadcrumb', () => {
  let wrapper;

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  const createComponent = ({
    workItemType = null,
    $route = {},
    listPath = '/epics',
    isGroup = true,
    workItemPlanningView = false,
    props = {},
  } = {}) => {
    wrapper = shallowMount(WorkItemBreadcrumb, {
      provide: {
        workItemType,
        glFeatures: {
          workItemPlanningView,
        },
        listPath,
        isGroup,
      },
      mocks: {
        $route,
      },
      propsData: { staticBreadcrumbs: [], ...props },
    });
  };

  describe('when the workspace is a group', () => {
    it('renders root `Work items` breadcrumb on work items list page', () => {
      createComponent({ workItemPlanningView: true });

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Work items',
          to: {
            name: 'workItemList',
            query: undefined,
            params: { type: 'work_items' },
          },
        },
      ]);
    });

    it('renders root `Issues` breadcrumb on work items list page', () => {
      createComponent();

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Issues',
          to: {
            name: 'workItemList',
            query: undefined,
            params: { type: 'issues' },
          },
        },
      ]);
    });

    it('renders root `Epics` breadcrumb on epics list page', () => {
      createComponent({ workItemType: WORK_ITEM_TYPE_NAME_EPIC });

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Epics',
          to: {
            name: 'workItemList',
            query: undefined,
            params: { type: 'epics' },
          },
        },
      ]);
    });
  });

  describe('when the workspace is a project', () => {
    describe('when in issues mode', () => {
      it('renders root breadcrumb with router link if on work item project issues list', () => {
        createComponent({ isGroup: false, listPath: '/issues' });

        expect(findBreadcrumb().props('items')).toEqual([
          {
            text: 'Issues',
            to: {
              name: 'workItemList',
              query: undefined,
              params: { type: 'issues' },
            },
          },
        ]);
      });
    });

    describe('when task is on work_items path with feature flag off', () => {
      it('renders root `Issues` breadcrumb with href to respect feature flag state', () => {
        createComponent({
          isGroup: false,
          listPath: '/issues',
          workItemViewForIssues: true,
          $route: { path: '/work_items/123' },
        });

        expect(findBreadcrumb().props('items')).toEqual([
          {
            text: 'Issues',
            href: '/issues',
          },
        ]);
      });
    });
  });

  it('renders `New` breadcrumb on new work item page', () => {
    createComponent({ $route: { name: 'new' } });

    expect(findBreadcrumb().props('items')).toEqual(
      expect.arrayContaining([{ text: 'New', to: { name: 'new', params: { type: 'issues' } } }]),
    );
  });

  it('combines static and dynamic breadcrumbs', () => {
    createComponent({
      $route: { name: 'workItem', params: { iid: '1', type: 'issues' }, path: '/1' },
      props: {
        staticBreadcrumbs: [{ text: 'Static', href: '/static' }],
      },
    });

    expect(findBreadcrumb().props('items')).toEqual([
      { text: 'Static', href: '/static' },
      {
        text: 'Issues',
        to: { name: 'workItemList', query: undefined, params: { type: 'issues' } },
      },
      { text: '#1', to: { name: 'workItem', params: { type: 'issues', iid: '1' } } },
    ]);
  });

  it('renders work item iid breadcrumb on work item detail page', () => {
    createComponent({
      $route: { name: 'workItem', params: { iid: '1', type: 'issues' }, path: '/1' },
    });

    expect(findBreadcrumb().props('items')).toEqual(
      expect.arrayContaining([
        { text: '#1', to: { name: 'workItem', params: { type: 'issues', iid: '1' } } },
      ]),
    );
  });
});
