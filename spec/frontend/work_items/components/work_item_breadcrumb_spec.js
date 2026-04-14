import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import WorkItemBreadcrumb from '~/work_items/components/work_item_breadcrumb.vue';
import { WORK_ITEM_TYPE_NAME_TICKET, ROUTES } from '~/work_items/constants';

describe('WorkItemBreadcrumb', () => {
  let wrapper;

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

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
