import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import CreateWorkItemPage from '~/work_items/pages/create_work_item.vue';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import workItemRelatedItemQuery from '~/work_items/graphql/work_item_related_item.query.graphql';
import { visitUrl, updateHistory, removeParams } from '~/lib/utils/url_utility';
import { setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import CreateWorkItemCancelConfirmationModal from '~/work_items/components/create_work_item_cancel_confirmation_modal.vue';
import {
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_NAME_ISSUE,
} from '~/work_items/constants';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.requireActual('~/lib/utils/url_utility').getParameterByName,
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
  visitUrl: jest.fn(),
  updateHistory: jest.fn(),
  removeParams: jest.fn(),
}));

jest.mock('~/work_items/graphql/cache_utils', () => ({
  setNewWorkItemCache: jest.fn(),
}));

const mockRelatedItem = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/234',
      reference: 'gitlab#100',
      webUrl: 'web/url',
      workItemType: {
        id: 'gid://gitlab/WorkitemType/1',
        name: 'Epic',
      },
    },
  },
};

describe('Create work item page component', () => {
  let wrapper;

  const relatedItemQueryHandler = jest.fn().mockResolvedValue(mockRelatedItem);

  const createComponent = ({ props = {}, provide = {}, $router = undefined, $route } = {}) => {
    wrapper = shallowMount(CreateWorkItemPage, {
      propsData: {
        workItemTypeEnum: WORK_ITEM_TYPE_ENUM_ISSUE,
        rootPageFullPath: 'gitlab-org',
        ...props,
      },
      apolloProvider: createMockApollo([[workItemRelatedItemQuery, relatedItemQueryHandler]]),
      mocks: {
        $router,
        $route,
      },
      provide: {
        fullPath: 'gitlab-org',
        isGroup: false,
        ...provide,
      },
      stubs: {
        GlModal,
      },
    });
  };

  const findCreateWorkItem = () => wrapper.findComponent(CreateWorkItem);
  const findCancelConfirmationModal = () =>
    wrapper.findComponent(CreateWorkItemCancelConfirmationModal);

  it('passes the isGroup prop to the CreateWorkItem component', () => {
    const pushMock = jest.fn();
    createComponent({ $router: { push: pushMock } });

    expect(findCreateWorkItem().props()).toMatchObject({
      isGroup: false,
      preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE,
    });
  });

  it('passes alwaysShowWorkItemTypeSelect prop as `true` to the CreateWorkItem component when isGroup is false', () => {
    const pushMock = jest.fn();
    createComponent({ $router: { push: pushMock } });

    expect(findCreateWorkItem().props()).toMatchObject({
      alwaysShowWorkItemTypeSelect: true,
      allowedWorkItemTypes: ['Incident', 'Issue', 'Task'],
    });
  });

  it('visits work item detail page after create if router is not present', () => {
    createComponent();

    findCreateWorkItem().vm.$emit('workItemCreated', {
      workItem: { webUrl: '/work_items/1234' },
      numberOfDiscussionsResolved: '',
    });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });

  it('reloads the page after create if work item created is an incident', () => {
    createComponent();

    findCreateWorkItem().vm.$emit('workItemCreated', {
      workItem: { webUrl: '/work_items/1234', workItemType: { name: 'Incident' } },
      numberOfDiscussionsResolved: '',
    });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });

  it('calls router.push after create if router is present', () => {
    const pushMock = jest.fn();
    createComponent({ $router: { push: pushMock } });

    wrapper.findComponent(CreateWorkItem).vm.$emit('workItemCreated', {
      workItem: { webUrl: '/work_items/1234', iid: '1234' },
      numberOfDiscussionsResolved: 1,
    });

    expect(pushMock).toHaveBeenCalledWith({
      name: 'workItem',
      params: { iid: '1234' },
      query: {
        resolves_discussion: 1,
      },
    });
  });

  describe('project selector', () => {
    it.each`
      workItemTypeEnum                | isGroup  | showProjectSelector
      ${WORK_ITEM_TYPE_ENUM_ISSUE}    | ${true}  | ${true}
      ${WORK_ITEM_TYPE_ENUM_INCIDENT} | ${true}  | ${true}
      ${WORK_ITEM_TYPE_ENUM_TASK}     | ${true}  | ${true}
      ${WORK_ITEM_TYPE_ENUM_EPIC}     | ${true}  | ${false}
      ${WORK_ITEM_TYPE_ENUM_ISSUE}    | ${false} | ${false}
      ${WORK_ITEM_TYPE_ENUM_INCIDENT} | ${false} | ${false}
      ${WORK_ITEM_TYPE_ENUM_TASK}     | ${false} | ${false}
      ${WORK_ITEM_TYPE_ENUM_EPIC}     | ${false} | ${false}
    `(
      'only renders when group and non-epic',
      ({ workItemTypeEnum, isGroup, showProjectSelector }) => {
        createComponent({
          props: { workItemTypeEnum },
          provide: { isGroup },
        });

        expect(findCreateWorkItem().props('showProjectSelector')).toBe(showProjectSelector);
      },
    );
  });

  describe('when the related_item_id url query param is present', () => {
    describe('when successful', () => {
      beforeEach(async () => {
        setWindowLocation('?related_item_id=gid://gitlab/WorkItem/234');
        createComponent();
        await waitForPromises();
      });

      it('queries for the related item', () => {
        expect(relatedItemQueryHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/WorkItem/234' });
      });

      it('passes the relatedItem to the CreateWorkItem component', () => {
        const { id, reference, webUrl, workItemType } = mockRelatedItem.data.workItem;
        expect(findCreateWorkItem().props('relatedItem')).toEqual({
          id,
          reference,
          webUrl,
          type: workItemType.name,
        });
      });
    });

    describe('when unsuccessful', () => {
      beforeEach(async () => {
        setWindowLocation('?related_item_id=gid://gitlab/WorkItem/234');
        relatedItemQueryHandler.mockRejectedValue('not found');
        createComponent();
        await waitForPromises();
      });

      it('removes the related_item_id parameter if there is a problem fetching the extra details', () => {
        expect(removeParams).toHaveBeenCalledWith(['related_item_id']);
        expect(updateHistory).toHaveBeenCalled();
      });
    });
  });

  describe('when the add_related_issue url query param is provided to the backend', () => {
    beforeEach(async () => {
      setHTMLFixture(`
          <div class="new-issue-params hidden">
            <div class="params-title">
              i am a title
            </div>
            <div class="params-description">
              i
              am
              a
              description!
            </div>
            <div class="params-add-related-issue">
              234
            </div>
            <div class="params-discussion-to-resolve">

            </div>
          </div>`);
      createComponent();
      await waitForPromises();
      await nextTick();
    });

    it('queries for the related item', () => {
      expect(relatedItemQueryHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/WorkItem/234' });
    });
  });

  describe('CreateWorkItemCancelConfirmationModal', () => {
    it('modal is rendered but not visible initially', () => {
      createComponent();

      expect(findCancelConfirmationModal().exists()).toBe(true);
      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
    });

    it('modal is displayed when user clicks cancel on the form', async () => {
      createComponent();

      findCreateWorkItem().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);
    });

    it('confirmation modal closes when user clicks "Continue Editing"', async () => {
      createComponent();

      findCreateWorkItem().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('continueEditing');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
    });

    it('confirmation modal closes when user clicks "Discard changes" and redirects to previous page when on project `work_items/new` route', async () => {
      const goMock = jest.fn();
      const historyMock = {
        base: '/gitlab-org/gitlab-test/-',
        current: {
          fullPath: '/work_items/new',
        },
      };
      const routeMock = {
        params: { type: 'work_items' },
      };

      createComponent({ $router: { history: historyMock, go: goMock }, $route: routeMock });

      findCreateWorkItem().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('discardDraft');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
      await nextTick();

      expect(goMock).toHaveBeenCalled();
    });

    it('confirmation modal closes when user clicks "Discard changes" and redirects to list page when on project `issues/new` route', async () => {
      const historyMock = {
        base: '/gitlab-org/gitlab-test/-',
        current: {
          fullPath: '/issues/new',
        },
      };
      const routeMock = {
        params: { type: 'issues' },
      };

      createComponent({ $router: { history: historyMock }, $route: routeMock });

      findCreateWorkItem().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('discardDraft');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
      expect(visitUrl).toHaveBeenCalledWith('/gitlab-org/gitlab-test/-/issues');
    });

    it('confirmation modal closes when user clicks "Discard changes" and redirects to list page when on group `work_items/new` route', async () => {
      const historyMock = {
        base: '/groups/gitlab-org/-',
        current: {
          fullPath: '/work_items/new',
        },
      };
      const routeMock = {
        params: { type: 'work_items' },
      };

      createComponent({
        provide: { isGroup: true },
        $router: { history: historyMock },
        $route: routeMock,
      });

      findCreateWorkItem().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('discardDraft');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
      expect(visitUrl).toHaveBeenCalledWith('/groups/gitlab-org/-/work_items');
    });

    it('confirmation modal closes when user clicks "Discard changes" and redirects to list page when on group `epics/new` route', async () => {
      const historyMock = {
        base: '/groups/gitlab-org/-',
        current: {
          fullPath: '/epics/new',
        },
      };
      const routeMock = {
        params: { type: 'epics' },
      };

      createComponent({
        provide: { isGroup: true },
        $router: { history: historyMock },
        $route: routeMock,
      });

      findCreateWorkItem().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('discardDraft');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
      expect(visitUrl).toHaveBeenCalledWith('/groups/gitlab-org/-/epics');
    });
  });
});
