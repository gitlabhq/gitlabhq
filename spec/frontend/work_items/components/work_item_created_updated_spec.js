import { GlAvatarLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { workItemResponseFactory, mockAssignees } from '../mock_data';

describe('WorkItemCreatedUpdated component', () => {
  let wrapper;
  let successHandler;
  let successByIidHandler;

  Vue.use(VueApollo);

  const findCreatedAt = () => wrapper.find('[data-testid="work-item-created"]');
  const findUpdatedAt = () => wrapper.find('[data-testid="work-item-updated"]');

  const findCreatedAtText = () => findCreatedAt().text().replace(/\s+/g, ' ');

  const createComponent = async ({
    workItemId = 'gid://gitlab/WorkItem/1',
    workItemIid = '1',
    fetchByIid = false,
    author = null,
    updatedAt,
  } = {}) => {
    const workItemQueryResponse = workItemResponseFactory({
      author,
      updatedAt,
    });
    const byIidResponse = {
      data: {
        workspace: {
          id: 'gid://gitlab/Project/1',
          workItems: {
            nodes: [workItemQueryResponse.data.workItem],
          },
        },
      },
    };

    successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
    successByIidHandler = jest.fn().mockResolvedValue(byIidResponse);

    const handlers = [
      [workItemQuery, successHandler],
      [workItemByIidQuery, successByIidHandler],
    ];

    wrapper = shallowMount(WorkItemCreatedUpdated, {
      apolloProvider: createMockApollo(handlers),
      propsData: { workItemId, workItemIid, fetchByIid, fullPath: '/some/project' },
      stubs: {
        GlAvatarLink,
        GlSprintf,
      },
    });

    await waitForPromises();
  };

  describe.each([true, false])('fetchByIid is %s', (fetchByIid) => {
    describe('work item id and iid undefined', () => {
      beforeEach(async () => {
        await createComponent({ workItemId: null, workItemIid: null, fetchByIid });
      });

      it('skips the work item query', () => {
        expect(successHandler).not.toHaveBeenCalled();
        expect(successByIidHandler).not.toHaveBeenCalled();
      });
    });

    it('shows author name and link', async () => {
      const author = mockAssignees[0];

      await createComponent({ fetchByIid, author });

      expect(findCreatedAtText()).toEqual(`Created by ${author.name}`);
    });

    it('shows created time when author is null', async () => {
      await createComponent({ fetchByIid, author: null });

      expect(findCreatedAtText()).toEqual('Created');
    });

    it('shows updated time', async () => {
      await createComponent({ fetchByIid });

      expect(findUpdatedAt().exists()).toBe(true);
    });

    it('does not show updated time for new work items', async () => {
      await createComponent({ fetchByIid, updatedAt: null });

      expect(findUpdatedAt().exists()).toBe(false);
    });
  });
});
