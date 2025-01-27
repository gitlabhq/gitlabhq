import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import WorkItemBreadcrumb from '~/work_items/components/work_item_breadcrumb.vue';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';

describe('WorkItemBreadcrumb', () => {
  let wrapper;

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  const createComponent = ({
    workItemType = null,
    workItemEpicsList = true,
    $route = {},
    listPath = '/epics',
    isGroup = true,
    workItemsViewPreference = false,
    workItemsAlpha = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemBreadcrumb, {
      provide: {
        workItemType,
        glFeatures: {
          workItemEpicsList,
          workItemsViewPreference,
          workItemsAlpha,
        },
        listPath,
        isGroup,
      },
      mocks: {
        $route,
      },
    });
  };

  describe('when the workspace is a group', () => {
    it('renders a href to the legacy epics page if the workItemEpicsList feature is disabled', () => {
      createComponent({ workItemType: WORK_ITEM_TYPE_ENUM_EPIC, workItemEpicsList: false });

      expect(findBreadcrumb().props('items')).toEqual([
        {
          text: 'Epics',
          href: '/epics',
        },
      ]);
    });

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
  });

  describe('when the workspace is a project', () => {
    describe('when work item view preference FF is disabled', () => {
      it('renders root `Issues` breadcrumb with href on work items list page', () => {
        createComponent({ isGroup: false, listPath: '/issues', workItemEpicsList: false });

        expect(findBreadcrumb().props('items')).toEqual([
          {
            text: 'Issues',
            href: '/issues',
          },
        ]);
      });
    });

    describe('when work item view preference FF is enabled', () => {
      it('renders root breadcrumb with href if user turned work item view off', () => {
        createComponent({
          isGroup: false,
          listPath: '/issues',
          workItemEpicsList: false,
          workItemsViewPreference: true,
        });

        expect(findBreadcrumb().props('items')).toEqual([
          {
            text: 'Issues',
            href: '/issues',
          },
        ]);
      });

      it('renders root breadcrumb with router link if user turned work item view on and alpha flag is on', () => {
        window.gon.current_user_use_work_items_view = true;

        createComponent({
          isGroup: false,
          listPath: '/issues',
          workItemEpicsList: false,
          workItemsViewPreference: true,
          workItemsAlpha: true,
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
        window.gon.current_user_use_work_items_view = true;

        createComponent({
          isGroup: false,
          listPath: '/issues',
          workItemEpicsList: false,
          workItemsViewPreference: true,
          workItemsAlpha: false,
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

  it('renders work item iid breadcrumb on work item detail page', () => {
    createComponent({ $route: { name: 'workItem', params: { iid: '1' }, path: '/1' } });

    expect(findBreadcrumb().props('items')).toEqual(
      expect.arrayContaining([{ text: '#1', to: '/1' }]),
    );
  });
});
