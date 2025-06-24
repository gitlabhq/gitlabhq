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
    workItemsAlpha = false,
    workItemPlanningView = false,
    workItemViewForIssues = false,
    props = {},
  } = {}) => {
    wrapper = shallowMount(WorkItemBreadcrumb, {
      provide: {
        workItemType,
        glFeatures: {
          workItemsAlpha,
          workItemPlanningView,
          workItemViewForIssues,
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
          },
        },
      ]);
    });
  });

  describe('when the workspace is a project', () => {
    describe('when in issues mode', () => {
      it('renders root `Issues` breadcrumb with href on work items list page', () => {
        createComponent({ isGroup: false, listPath: '/issues' });

        expect(findBreadcrumb().props('items')).toEqual([
          {
            text: 'Issues',
            href: '/issues',
          },
        ]);
      });

      it('renders root breadcrumb with router link if user turned work item view on and alpha flag is on', () => {
        createComponent({
          isGroup: false,
          listPath: '/issues',
          workItemsAlpha: true,
          workItemViewForIssues: true,
        });

        expect(findBreadcrumb().props('items')).toEqual([
          {
            text: 'Issues',
            to: {
              name: 'workItemList',
              query: undefined,
            },
          },
        ]);
      });

      it('renders root breadcrumb with href if user turned work item view on and alpha flag is off', () => {
        createComponent({
          isGroup: false,
          listPath: '/issues',
          workItemsAlpha: false,
          workItemViewForIssues: true,
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
      expect.arrayContaining([{ text: 'New', to: 'new' }]),
    );
  });

  it('combines static and dynamic breadcrumbs', () => {
    createComponent({
      $route: { name: 'workItem', params: { iid: '1' }, path: '/1' },
      props: {
        staticBreadcrumbs: [{ text: 'Static', href: '/static' }],
      },
    });

    expect(findBreadcrumb().props('items')).toEqual([
      { text: 'Static', href: '/static' },
      { text: 'Issues', to: { name: 'workItemList', query: undefined } },
      { text: '#1', to: '/1' },
    ]);
  });

  it('renders work item iid breadcrumb on work item detail page', () => {
    createComponent({ $route: { name: 'workItem', params: { iid: '1' }, path: '/1' } });

    expect(findBreadcrumb().props('items')).toEqual(
      expect.arrayContaining([{ text: '#1', to: '/1' }]),
    );
  });
});
