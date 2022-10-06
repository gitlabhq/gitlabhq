import Vue, { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import currentUserNamespaceQueryResponse from 'test_fixtures/graphql/projects/settings/current_user_namespace.query.graphql.json';
import transferLocationsResponsePage1 from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import transferLocationsResponsePage2 from 'test_fixtures/api/projects/transfer_locations_page_2.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TransferProjectForm from '~/projects/settings/components/transfer_project_form.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select_deprecated.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import currentUserNamespaceQuery from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';
import { getTransferLocations } from '~/api/projects_api';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/api/projects_api', () => ({
  getTransferLocations: jest.fn(),
}));

describe('Transfer project form', () => {
  let wrapper;

  const projectId = '1';
  const confirmButtonText = 'Confirm';
  const confirmationPhrase = 'You must construct additional pylons!';

  Vue.use(VueApollo);

  const defaultQueryHandler = jest.fn().mockResolvedValue(currentUserNamespaceQueryResponse);
  const mockResolvedGetTransferLocations = ({
    data = transferLocationsResponsePage1,
    page = '1',
    nextPage = '2',
    prevPage = null,
  } = {}) => {
    getTransferLocations.mockResolvedValueOnce({
      data,
      headers: {
        'x-per-page': '2',
        'x-page': page,
        'x-total': '4',
        'x-total-pages': '2',
        'x-next-page': nextPage,
        'x-prev-page': prevPage,
      },
    });
  };
  const mockRejectedGetTransferLocations = () => {
    const error = new Error();

    getTransferLocations.mockRejectedValueOnce(error);
  };

  const createComponent = ({
    requestHandlers = [[currentUserNamespaceQuery, defaultQueryHandler]],
  } = {}) => {
    wrapper = shallowMountExtended(TransferProjectForm, {
      provide: {
        projectId,
      },
      propsData: {
        confirmButtonText,
        confirmationPhrase,
      },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findNamespaceSelect = () => wrapper.findComponent(NamespaceSelect);
  const showNamespaceSelect = async () => {
    findNamespaceSelect().vm.$emit('show');
    await waitForPromises();
  };
  const findConfirmDanger = () => wrapper.findComponent(ConfirmDanger);
  const findAlert = () => wrapper.findComponent(GlAlert);

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
    const [selectedItem] = transferLocationsResponsePage1;

    const arrange = async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showNamespaceSelect();
      findNamespaceSelect().vm.$emit('select', selectedItem);
    };

    it('emits the `selectNamespace` event when a namespace is selected', async () => {
      await arrange();

      const args = [selectedItem.id];

      expect(wrapper.emitted('selectNamespace')).toEqual([args]);
    });

    it('enables the confirm button', async () => {
      await arrange();

      expect(findConfirmDanger().attributes('disabled')).toBeUndefined();
    });

    it('clicking the confirm button emits the `confirm` event', async () => {
      await arrange();

      findConfirmDanger().vm.$emit('confirm');

      expect(wrapper.emitted('confirm')).toBeDefined();
    });
  });

  describe('when `NamespaceSelect` is opened', () => {
    it('fetches user and group namespaces and passes correct props to `NamespaceSelect` component', async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showNamespaceSelect();

      const { namespace } = currentUserNamespaceQueryResponse.data.currentUser;

      expect(findNamespaceSelect().props()).toMatchObject({
        userNamespaces: [
          {
            id: getIdFromGraphQLId(namespace.id),
            humanName: namespace.fullName,
          },
        ],
        groupNamespaces: transferLocationsResponsePage1.map(({ id, full_name: humanName }) => ({
          id,
          humanName,
        })),
        hasNextPageOfGroups: true,
        isLoading: false,
        isSearchLoading: false,
        shouldFilterNamespaces: false,
      });
    });

    describe('when namespaces have already been fetched', () => {
      beforeEach(async () => {
        mockResolvedGetTransferLocations();
        createComponent();
        await showNamespaceSelect();
      });

      it('does not fetch namespaces', async () => {
        getTransferLocations.mockClear();
        defaultQueryHandler.mockClear();

        await showNamespaceSelect();

        expect(getTransferLocations).not.toHaveBeenCalled();
        expect(defaultQueryHandler).not.toHaveBeenCalled();
      });
    });

    describe('when `getTransferLocations` API call fails', () => {
      it('displays error alert', async () => {
        mockRejectedGetTransferLocations();
        createComponent();
        await showNamespaceSelect();

        expect(findAlert().exists()).toBe(true);
      });
    });

    describe('when `currentUser` GraphQL query fails', () => {
      it('displays error alert', async () => {
        mockResolvedGetTransferLocations();
        const error = new Error();
        createComponent({
          requestHandlers: [[currentUserNamespaceQuery, jest.fn().mockRejectedValueOnce(error)]],
        });
        await showNamespaceSelect();

        expect(findAlert().exists()).toBe(true);
      });
    });
  });

  describe('when `search` event is fired', () => {
    const arrange = async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showNamespaceSelect();
      mockResolvedGetTransferLocations();
      findNamespaceSelect().vm.$emit('search', 'foo');
      await nextTick();
    };

    it('sets `isSearchLoading` prop to `true`', async () => {
      await arrange();

      expect(findNamespaceSelect().props('isSearchLoading')).toBe(true);
    });

    it('passes `search` param to API call', async () => {
      await arrange();

      await waitForPromises();

      expect(getTransferLocations).toHaveBeenCalledWith(
        projectId,
        expect.objectContaining({ search: 'foo' }),
      );
    });

    describe('when `getTransferLocations` API call fails', () => {
      it('displays dismissible error alert', async () => {
        mockResolvedGetTransferLocations();
        createComponent();
        await showNamespaceSelect();
        mockRejectedGetTransferLocations();
        findNamespaceSelect().vm.$emit('search', 'foo');
        await waitForPromises();

        const alert = findAlert();

        expect(alert.exists()).toBe(true);

        alert.vm.$emit('dismiss');
        await nextTick();

        expect(alert.exists()).toBe(false);
      });
    });
  });

  describe('when `load-more-groups` event is fired', () => {
    const arrange = async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showNamespaceSelect();

      mockResolvedGetTransferLocations({
        data: transferLocationsResponsePage2,
        page: '2',
        nextPage: null,
        prevPage: '1',
      });

      findNamespaceSelect().vm.$emit('load-more-groups');
      await nextTick();
    };

    it('sets `isLoading` prop to `true`', async () => {
      await arrange();

      expect(findNamespaceSelect().props('isLoading')).toBe(true);
    });

    it('passes `page` param to API call', async () => {
      await arrange();

      await waitForPromises();

      expect(getTransferLocations).toHaveBeenCalledWith(
        projectId,
        expect.objectContaining({ page: 2 }),
      );
    });

    it('updates `groupNamespaces` prop with new groups', async () => {
      await arrange();

      await waitForPromises();

      expect(findNamespaceSelect().props('groupNamespaces')).toMatchObject(
        [...transferLocationsResponsePage1, ...transferLocationsResponsePage2].map(
          ({ id, full_name: humanName }) => ({
            id,
            humanName,
          }),
        ),
      );
    });

    it('updates `hasNextPageOfGroups` prop', async () => {
      await arrange();

      await waitForPromises();

      expect(findNamespaceSelect().props('hasNextPageOfGroups')).toBe(false);
    });

    describe('when `getTransferLocations` API call fails', () => {
      it('displays error alert', async () => {
        mockResolvedGetTransferLocations();
        createComponent();
        await showNamespaceSelect();
        mockRejectedGetTransferLocations();
        findNamespaceSelect().vm.$emit('load-more-groups');
        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
      });
    });
  });
});
