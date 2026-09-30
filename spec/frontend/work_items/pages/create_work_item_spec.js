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
import { CREATION_CONTEXT_NEW_ROUTE, ROUTES } from '~/work_items/constants';
import { getDraftWorkItemType } from '~/work_items/utils';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.requireActual('~/lib/utils/url_utility').getParameterByName,
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
  visitUrl: jest.fn(),
  updateHistory: jest.fn(),
  removeParams: jest.fn(),
  getBaseURL: jest.fn().mockReturnValue('http://127.0.0.0:3000'),
  relativePathToAbsolute: jest.fn().mockImplementation((path) => path),
}));

jest.mock('~/work_items/graphql/cache_utils', () => ({
  setNewWorkItemCache: jest.fn(),
}));

jest.mock('~/work_items/utils', () => ({
  ...jest.requireActual('~/work_items/utils'),
  getDraftWorkItemType: jest.fn(),
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

  const createComponent = ({ provide = {}, $router = undefined } = {}) => {
    wrapper = shallowMount(CreateWorkItemPage, {
      propsData: {
        rootPageFullPath: 'gitlab-org',
      },
      apolloProvider: createMockApollo([[workItemRelatedItemQuery, relatedItemQueryHandler]]),
      mocks: {
        $router,
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

  it('renders CreateWorkItem component with expected props', () => {
    const pushMock = jest.fn();
    createComponent({ $router: { push: pushMock } });

    expect(findCreateWorkItem().props()).toMatchObject({
      creationContext: CREATION_CONTEXT_NEW_ROUTE,
      isGroup: false,
      preselectedWorkItemType: '',
    });
  });

  describe('preselected work item type', () => {
    describe.each`
      type            | expected
      ${'ISSUE'}      | ${'Issue'}
      ${'INCIDENT'}   | ${'Incident'}
      ${'KEY_RESULT'} | ${'Key Result'}
      ${'test_case'}  | ${'Test Case'}
    `('when the `type` query param is $type', ({ type, expected }) => {
      beforeEach(() => {
        setWindowLocation(`?type=${type}`);
        createComponent();
      });

      it(`passes "${expected}" to CreateWorkItem`, () => {
        expect(findCreateWorkItem().props('preselectedWorkItemType')).toBe(expected);
      });
    });

    describe('when the `issue[issue_type]` query param is present', () => {
      beforeEach(() => {
        setHTMLFixture(`<div class="params-issue-type">incident</div>`);
        setWindowLocation('?issue[issue_type]=incident');
        createComponent();
      });

      it('passes the type set by the backend to CreateWorkItem', () => {
        expect(findCreateWorkItem().props('preselectedWorkItemType')).toBe('Incident');
      });
    });

    describe('when there is a draft work item type', () => {
      beforeEach(() => {
        getDraftWorkItemType.mockReturnValue({ name: 'Task' });
      });

      describe('when there are no type query params', () => {
        beforeEach(() => {
          createComponent();
        });

        it('reads the draft for the new route context', () => {
          expect(getDraftWorkItemType).toHaveBeenCalledWith({
            fullPath: 'gitlab-org',
            context: 'new-route',
          });
        });

        it('passes the draft type to CreateWorkItem', () => {
          expect(findCreateWorkItem().props('preselectedWorkItemType')).toBe('Task');
        });
      });
    });
  });

  it('passes alwaysShowWorkItemTypeSelect prop as `true` to the CreateWorkItem component when isGroup is false', () => {
    const pushMock = jest.fn();
    createComponent({ $router: { push: pushMock } });

    expect(findCreateWorkItem().props()).toMatchObject({
      alwaysShowWorkItemTypeSelect: true,
    });
  });

  it('visits work item detail page after create if router is not present', () => {
    createComponent();

    findCreateWorkItem().vm.$emit('work-item-created', {
      workItem: { webUrl: '/work_items/1234' },
      numberOfDiscussionsResolved: '',
    });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });

  it('reloads the page after create if work item created is an incident', () => {
    createComponent();

    findCreateWorkItem().vm.$emit('work-item-created', {
      workItem: { webUrl: '/work_items/1234', workItemType: { name: 'Incident' } },
      numberOfDiscussionsResolved: '',
    });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });

  it('calls router.push after create if router is present', () => {
    const pushMock = jest.fn();
    createComponent({ $router: { push: pushMock } });

    wrapper.findComponent(CreateWorkItem).vm.$emit('work-item-created', {
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
      workItemType  | isGroup  | showProjectSelector
      ${'Issue'}    | ${true}  | ${true}
      ${'Incident'} | ${true}  | ${true}
      ${'Task'}     | ${true}  | ${true}
      ${'Epic'}     | ${true}  | ${false}
      ${'Issue'}    | ${false} | ${false}
      ${'Incident'} | ${false} | ${false}
      ${'Task'}     | ${false} | ${false}
      ${'Epic'}     | ${false} | ${false}
    `(
      'only renders when group and non-epic',
      async ({ workItemType, isGroup, showProjectSelector }) => {
        createComponent({ provide: { isGroup } });

        findCreateWorkItem().vm.$emit('update-type', workItemType);
        await nextTick();

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
    const setWorkItemType = async (type = 'Issue') => {
      findCreateWorkItem().vm.$emit('update-type', type);
      await nextTick();
    };

    it('modal is not rendered before the work item type is known', () => {
      createComponent();

      expect(findCancelConfirmationModal().exists()).toBe(false);
    });

    it('modal is rendered but not visible initially', async () => {
      createComponent();
      await setWorkItemType();

      expect(findCancelConfirmationModal().exists()).toBe(true);
      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
    });

    it('modal is displayed when user clicks cancel on the form', async () => {
      createComponent();
      await setWorkItemType();

      findCreateWorkItem().vm.$emit('confirm-cancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);
    });

    it('confirmation modal closes when user clicks "Continue Editing"', async () => {
      createComponent();
      await setWorkItemType();

      findCreateWorkItem().vm.$emit('confirm-cancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('continue-editing');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
    });

    describe('when user clicks "Discard changes"', () => {
      let pushMock;
      let goMock;

      const discardDraft = async () => {
        findCreateWorkItem().vm.$emit('confirm-cancel');
        await nextTick();

        findCancelConfirmationModal().vm.$emit('discard-draft');
        await nextTick();
      };

      beforeEach(() => {
        pushMock = jest.fn();
        goMock = jest.fn();
      });

      it('closes the confirmation modal and redirects to the index page', async () => {
        setWindowLocation('/work_items/new');
        createComponent({ $router: { push: pushMock, go: goMock } });
        await setWorkItemType();

        await discardDraft();

        expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
        expect(pushMock).toHaveBeenCalledWith({ name: ROUTES.index });
      });

      describe('when the type query param is INCIDENT', () => {
        it('closes the confirmation modal and returns to the previous page', async () => {
          setWindowLocation('/work_items/new?type=INCIDENT');
          createComponent({ $router: { push: pushMock, go: goMock } });
          await setWorkItemType('Incident');

          await discardDraft();

          expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
          expect(goMock).toHaveBeenCalledWith(-1);
        });
      });
    });
  });
});
