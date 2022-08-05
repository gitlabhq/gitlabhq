import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import searchNamespacesWhereUserCanTransferProjectsQueryResponsePage1 from 'test_fixtures/graphql/projects/settings/search_namespaces_where_user_can_transfer_projects_page_1.query.graphql.json';
import searchNamespacesWhereUserCanTransferProjectsQueryResponsePage2 from 'test_fixtures/graphql/projects/settings/search_namespaces_where_user_can_transfer_projects_page_2.query.graphql.json';
import {
  groupNamespaces,
  userNamespaces,
} from 'jest/vue_shared/components/namespace_select/mock_data';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TransferProjectForm from '~/projects/settings/components/transfer_project_form.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import searchNamespacesWhereUserCanTransferProjectsQuery from '~/projects/settings/graphql/queries/search_namespaces_where_user_can_transfer_projects.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';

describe('Transfer project form', () => {
  let wrapper;

  const confirmButtonText = 'Confirm';
  const confirmationPhrase = 'You must construct additional pylons!';

  const runDebounce = () => jest.runAllTimers();

  Vue.use(VueApollo);

  const defaultQueryHandler = jest
    .fn()
    .mockResolvedValue(searchNamespacesWhereUserCanTransferProjectsQueryResponsePage1);

  const createComponent = ({
    requestHandlers = [[searchNamespacesWhereUserCanTransferProjectsQuery, defaultQueryHandler]],
  } = {}) => {
    wrapper = shallowMountExtended(TransferProjectForm, {
      propsData: {
        userNamespaces,
        groupNamespaces,
        confirmButtonText,
        confirmationPhrase,
      },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findNamespaceSelect = () => wrapper.findComponent(NamespaceSelect);
  const findConfirmDanger = () => wrapper.findComponent(ConfirmDanger);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the namespace selector', () => {
    createComponent();

    expect(findNamespaceSelect().exists()).toBe(true);
  });

  it('renders the confirm button', () => {
    createComponent();

    expect(findConfirmDanger().exists()).toBe(true);
  });

  it('disables the confirm button by default', () => {
    createComponent();

    expect(findConfirmDanger().attributes('disabled')).toBe('true');
  });

  describe('with a selected namespace', () => {
    const [selectedItem] = groupNamespaces;

    beforeEach(() => {
      createComponent();

      findNamespaceSelect().vm.$emit('select', selectedItem);
    });

    it('emits the `selectNamespace` event when a namespace is selected', () => {
      const args = [selectedItem.id];

      expect(wrapper.emitted('selectNamespace')).toEqual([args]);
    });

    it('enables the confirm button', () => {
      expect(findConfirmDanger().attributes('disabled')).toBeUndefined();
    });

    it('clicking the confirm button emits the `confirm` event', () => {
      findConfirmDanger().vm.$emit('confirm');

      expect(wrapper.emitted('confirm')).toBeDefined();
    });
  });

  it('passes correct props to `NamespaceSelect` component', async () => {
    createComponent();

    runDebounce();
    await waitForPromises();

    const {
      namespace,
      groups,
    } = searchNamespacesWhereUserCanTransferProjectsQueryResponsePage1.data.currentUser;

    expect(findNamespaceSelect().props()).toMatchObject({
      userNamespaces: [
        {
          id: getIdFromGraphQLId(namespace.id),
          humanName: namespace.fullName,
        },
      ],
      groupNamespaces: groups.nodes.map((node) => ({
        id: getIdFromGraphQLId(node.id),
        humanName: node.fullName,
      })),
      hasNextPageOfGroups: true,
      isLoadingMoreGroups: false,
      isSearchLoading: false,
      shouldFilterNamespaces: false,
    });
  });

  describe('when `search` event is fired', () => {
    const arrange = async () => {
      createComponent();

      findNamespaceSelect().vm.$emit('search', 'foo');

      await nextTick();
    };

    it('sets `isSearchLoading` prop to `true`', async () => {
      await arrange();

      expect(findNamespaceSelect().props('isSearchLoading')).toBe(true);
    });

    it('passes `search` variable to query', async () => {
      await arrange();

      runDebounce();
      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(expect.objectContaining({ search: 'foo' }));
    });
  });

  describe('when `load-more-groups` event is fired', () => {
    let queryHandler;

    const arrange = async () => {
      queryHandler = jest.fn();
      queryHandler.mockResolvedValueOnce(
        searchNamespacesWhereUserCanTransferProjectsQueryResponsePage1,
      );
      queryHandler.mockResolvedValueOnce(
        searchNamespacesWhereUserCanTransferProjectsQueryResponsePage2,
      );

      createComponent({
        requestHandlers: [[searchNamespacesWhereUserCanTransferProjectsQuery, queryHandler]],
      });

      runDebounce();
      await waitForPromises();

      findNamespaceSelect().vm.$emit('load-more-groups');
      await nextTick();
    };

    it('sets `isLoadingMoreGroups` prop to `true`', async () => {
      await arrange();

      expect(findNamespaceSelect().props('isLoadingMoreGroups')).toBe(true);
    });

    it('passes `after` and `first` variables to query', async () => {
      await arrange();

      runDebounce();
      await waitForPromises();

      expect(queryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          first: 25,
          after:
            searchNamespacesWhereUserCanTransferProjectsQueryResponsePage1.data.currentUser.groups
              .pageInfo.endCursor,
        }),
      );
    });

    it('updates `groupNamespaces` prop with new groups', async () => {
      await arrange();

      runDebounce();
      await waitForPromises();

      expect(findNamespaceSelect().props('groupNamespaces')).toEqual(
        [
          ...searchNamespacesWhereUserCanTransferProjectsQueryResponsePage1.data.currentUser.groups
            .nodes,
          ...searchNamespacesWhereUserCanTransferProjectsQueryResponsePage2.data.currentUser.groups
            .nodes,
        ].map((node) => ({
          id: getIdFromGraphQLId(node.id),
          humanName: node.fullName,
        })),
      );
    });

    it('updates `hasNextPageOfGroups` prop', async () => {
      await arrange();

      runDebounce();
      await waitForPromises();

      expect(findNamespaceSelect().props('hasNextPageOfGroups')).toBe(false);
    });
  });
});
