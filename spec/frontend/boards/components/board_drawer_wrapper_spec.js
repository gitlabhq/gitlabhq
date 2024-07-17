import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardDrawerWrapper from '~/boards/components/board_drawer_wrapper.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import { rawIssue } from '../mock_data';

Vue.use(VueApollo);

const mockRefetchQueries = jest.fn();

describe('BoardDrawerWrapper', () => {
  let wrapper;

  const findActiveIssuable = () => wrapper.findByTestId('active-issuable');
  const findCloseButton = () => wrapper.findByTestId('close-button');
  const findUpdateAttributeButton = () => wrapper.findByTestId('update-attribute-button');

  const createComponent = (propsData = {}) => {
    const mockApollo = createMockApollo([], resolvers);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: { ...rawIssue, listId: 'gid://gitlab/List/3' },
      },
    });
    mockApollo.clients.defaultClient.refetchQueries = mockRefetchQueries;

    wrapper = shallowMountExtended(BoardDrawerWrapper, {
      propsData: {
        backlogListId: 'gid://gitlab/List/1',
        closedListId: 'gid://gitlab/List/2',
        ...propsData,
      },
      apolloProvider: mockApollo,
      scopedSlots: {
        default: `
          <div>
            <span data-testid="active-issuable" v-if="props.activeIssuable.listId"/>
            <button data-testid="close-button" @click="props.onDrawerClosed">Close</button>
            <button data-testid="update-attribute-button" @click="props.onAttributeUpdated({  ids: ['1'], type: 'assignee'})">Update attribute</button>
            <button data-testid="delete-issuable" @click="props.onIssuableDeleted">Delete issuable</button>
          </div>
        `,
      },
    });
  };

  it('renders active issuable', () => {
    createComponent();

    expect(findActiveIssuable().exists()).toBe(true);
  });

  it('hides active issuable on drawer close', async () => {
    createComponent();

    findCloseButton().trigger('click');
    await waitForPromises();

    expect(findActiveIssuable().exists()).toBe(false);
  });

  it('does not refetch lists if there were no changes to attributes', async () => {
    createComponent();

    findCloseButton().trigger('click');
    await waitForPromises();

    expect(mockRefetchQueries).not.toHaveBeenCalled();
  });

  it('does not refetch lists if active issuable was on the closed list', async () => {
    createComponent({ closedListId: 'gid://gitlab/List/3' });

    findUpdateAttributeButton().trigger('click');
    findCloseButton().trigger('click');
    await waitForPromises();

    expect(mockRefetchQueries).not.toHaveBeenCalled();
  });

  it('refetches lists if active issuable was not on the closed list', async () => {
    createComponent();

    findUpdateAttributeButton().trigger('click');
    findCloseButton().trigger('click');
    await waitForPromises();

    expect(mockRefetchQueries).toHaveBeenCalledTimes(2);
  });

  it('refetches lists on issuable delete', async () => {
    createComponent();

    wrapper.findByTestId('delete-issuable').trigger('click');
    await waitForPromises();

    expect(mockRefetchQueries).toHaveBeenCalledTimes(1);
  });
});
