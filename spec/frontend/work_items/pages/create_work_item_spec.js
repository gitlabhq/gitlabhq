import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import CreateWorkItemPage from '~/work_items/pages/create_work_item.vue';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import workItemRelatedItemQuery from '~/work_items/graphql/work_item_related_item.query.graphql';
import { visitUrl, updateHistory, removeParams } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.requireActual('~/lib/utils/url_utility').getParameterByName,
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
  visitUrl: jest.fn(),
  updateHistory: jest.fn(),
  removeParams: jest.fn(),
}));

const mockRelatedItem = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/234',
      reference: 'gitlab#100',
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

  const createComponent = ($router = undefined, isGroup = true) => {
    wrapper = shallowMount(CreateWorkItemPage, {
      propsData: {
        workItemTypeName: 'issue',
      },
      apolloProvider: createMockApollo([[workItemRelatedItemQuery, relatedItemQueryHandler]]),
      mocks: {
        $router,
      },
      provide: {
        fullPath: 'gitlab-org',
        isGroup,
      },
    });
  };

  const findCreateWorkItem = () => wrapper.findComponent(CreateWorkItem);

  it('passes the isGroup prop to the CreateWorkItem component', () => {
    const pushMock = jest.fn();
    createComponent({ push: pushMock }, false);

    expect(findCreateWorkItem().props()).toMatchObject({
      isGroup: false,
      workItemTypeName: 'issue',
    });
  });

  it('visits work item detail page after create if router is not present', () => {
    createComponent();

    findCreateWorkItem().vm.$emit('workItemCreated', { webUrl: '/work_items/1234' });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });

  it('calls router.push after create if router is present', () => {
    const pushMock = jest.fn();
    createComponent({ push: pushMock });

    wrapper
      .findComponent(CreateWorkItem)
      .vm.$emit('workItemCreated', { webUrl: '/work_items/1234', iid: '1234' });

    expect(pushMock).toHaveBeenCalledWith({ name: 'workItem', params: { iid: '1234' } });
  });

  describe('when the related_item_id url query param is present', () => {
    describe('when successful', () => {
      beforeEach(async () => {
        setWindowLocation('?related_item_id=gid://gitlab/WorkItem/234');
        createComponent();
        await waitForPromises();
      });

      it('queries for the releated item', () => {
        expect(relatedItemQueryHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/WorkItem/234' });
      });

      it('passes the relatedItem to the CreateWorkItem component', () => {
        const { id, reference, workItemType } = mockRelatedItem.data.workItem;
        expect(findCreateWorkItem().props('relatedItem')).toEqual({
          id,
          reference,
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
});
