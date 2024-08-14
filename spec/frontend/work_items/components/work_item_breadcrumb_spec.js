import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import WorkItemBreadcrumb from '~/work_items/components/work_item_breadcrumb.vue';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';

describe('WorkItemBreadcrumb', () => {
  let wrapper;

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  const createComponent = ({ workItemType = null, $route = {} } = {}) => {
    wrapper = shallowMount(WorkItemBreadcrumb, {
      provide: {
        workItemType,
      },
      mocks: {
        $route,
      },
    });
  };

  it('renders root `Work items` breadcrumb on work items list page', () => {
    createComponent();

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

  it('renders root `Epics` breadcrumb on epics list page', () => {
    createComponent({ workItemType: WORK_ITEM_TYPE_ENUM_EPIC });

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

  it('renders `New` breadcrumb on new work item page', () => {
    createComponent({ $route: { name: 'new' } });

    expect(findBreadcrumb().props('items')).toEqual([
      {
        text: 'Work items',
        to: {
          name: 'workItemList',
          query: undefined,
        },
      },
      { text: 'New', to: 'new' },
    ]);
  });

  it('renders work item iid breadcrumb on work item detail page', () => {
    createComponent({ $route: { name: 'workItem', params: { iid: '1' }, path: '/1' } });

    expect(findBreadcrumb().props('items')).toEqual([
      {
        text: 'Work items',
        to: {
          name: 'workItemList',
          query: undefined,
        },
      },
      { text: '#1', to: '/1' },
    ]);
  });
});
