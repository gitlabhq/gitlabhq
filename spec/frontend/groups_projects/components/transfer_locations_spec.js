import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlIntersectionObserver,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import currentUserNamespaceQueryResponse from 'test_fixtures/graphql/projects/settings/current_user_namespace.query.graphql.json';
import transferLocationsResponsePage1 from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import transferLocationsResponsePage2 from 'test_fixtures/api/projects/transfer_locations_page_2.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import TransferLocations, { i18n } from '~/groups_projects/components/transfer_locations.vue';
import { getTransferLocations } from '~/api/projects_api';
import currentUserNamespaceQuery from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';
import { ENTER_KEY } from '~/lib/utils/keys';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

jest.mock('~/api/projects_api', () => ({
  getTransferLocations: jest.fn(),
}));

describe('TransferLocations', () => {
  let wrapper;

  // Default data
  const resourceId = '1';
  const resourcePath = 'test-project';
  const defaultPropsData = {
    groupTransferLocationsApiMethod: getTransferLocations,
    value: null,
  };
  const additionalDropdownItem = {
    id: -1,
    humanName: 'No parent group',
  };

  // Mock requests
  const defaultQueryHandler = jest.fn().mockResolvedValue(currentUserNamespaceQueryResponse);
  const mockResolvedGetTransferLocations = ({
    data = transferLocationsResponsePage1,
    page = '1',
    nextPage = '2',
    total = '4',
    totalPages = '2',
    prevPage = null,
  } = {}) => {
    getTransferLocations.mockResolvedValueOnce({
      data,
      headers: {
        'x-per-page': '2',
        'x-page': page,
        'x-total': total,
        'x-total-pages': totalPages,
        'x-next-page': nextPage,
        'x-prev-page': prevPage,
      },
    });
  };
  const mockRejectedGetTransferLocations = () => {
    const error = new Error();

    getTransferLocations.mockRejectedValueOnce(error);
  };

  // VTU wrapper helpers
  Vue.use(VueApollo);
  const createComponent = ({
    provide = {},
    propsData = {},
    requestHandlers = [[currentUserNamespaceQuery, defaultQueryHandler]],
  } = {}) => {
    wrapper = mountExtended(TransferLocations, {
      provide: {
        resourceId,
        resourcePath,
        ...provide,
      },
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const showDropdown = async () => {
    findDropdown().vm.$emit('show');
    await waitForPromises();
  };
  const findUserTransferLocations = () =>
    wrapper
      .findByTestId('user-transfer-locations')
      .findAllComponents(GlDropdownItem)
      .wrappers.map((dropdownItem) => dropdownItem.text());
  const findGroupTransferLocations = () =>
    wrapper
      .findByTestId('group-transfer-locations')
      .findAllComponents(GlDropdownItem)
      .wrappers.map((dropdownItem) => dropdownItem.text());
  const findDropdownItemByText = (text) =>
    wrapper
      .findAllComponents(GlDropdownItem)
      .wrappers.find((dropdownItem) => dropdownItem.text() === text);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const searchEmitInput = (searchTerm = 'foo') => findSearch().vm.$emit('input', searchTerm);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const intersectionObserverEmitAppear = () => findIntersectionObserver().vm.$emit('appear');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('when `GlDropdown` is opened', () => {
    it('shows loading icon', async () => {
      getTransferLocations.mockReturnValueOnce(new Promise(() => {}));
      createComponent();
      findDropdown().vm.$emit('show');
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('fetches and renders user and group transfer locations', async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showDropdown();

      const { namespace } = currentUserNamespaceQueryResponse.data.currentUser;

      expect(findUserTransferLocations()).toEqual([namespace.fullName]);
      expect(findGroupTransferLocations()).toEqual(
        transferLocationsResponsePage1.map((transferLocation) => transferLocation.full_name),
      );
    });

    describe('when `showUserTransferLocations` prop is `false`', () => {
      it('does not fetch user transfer locations', async () => {
        mockResolvedGetTransferLocations();
        createComponent({
          propsData: {
            showUserTransferLocations: false,
          },
        });
        await showDropdown();

        expect(wrapper.findByTestId('user-transfer-locations').exists()).toBe(false);
      });
    });

    describe('when `additionalDropdownItems` prop is passed', () => {
      it('displays additional dropdown items', async () => {
        mockResolvedGetTransferLocations();
        createComponent({
          propsData: {
            additionalDropdownItems: [additionalDropdownItem],
          },
        });
        await showDropdown();

        expect(findDropdownItemByText(additionalDropdownItem.humanName).exists()).toBe(true);
      });

      describe('when loading', () => {
        it('does not display additional dropdown items', async () => {
          getTransferLocations.mockReturnValueOnce(new Promise(() => {}));
          createComponent({
            propsData: {
              additionalDropdownItems: [additionalDropdownItem],
            },
          });
          findDropdown().vm.$emit('show');
          await nextTick();

          expect(findDropdownItemByText(additionalDropdownItem.humanName)).toBeUndefined();
        });
      });
    });

    describe('when transfer locations have already been fetched', () => {
      beforeEach(async () => {
        mockResolvedGetTransferLocations();
        createComponent();
        await showDropdown();
      });

      it('does not fetch transfer locations', async () => {
        getTransferLocations.mockClear();
        defaultQueryHandler.mockClear();

        await showDropdown();

        expect(getTransferLocations).not.toHaveBeenCalled();
        expect(defaultQueryHandler).not.toHaveBeenCalled();
      });
    });

    describe('when `getTransferLocations` API call fails', () => {
      it('displays dismissible error alert', async () => {
        mockRejectedGetTransferLocations();
        createComponent();
        await showDropdown();

        const alert = findAlert();

        expect(alert.exists()).toBe(true);

        alert.vm.$emit('dismiss');
        await nextTick();

        expect(alert.exists()).toBe(false);
      });
    });

    describe('when `currentUser` GraphQL query fails', () => {
      it('displays error alert', async () => {
        mockResolvedGetTransferLocations();
        const error = new Error();
        createComponent({
          requestHandlers: [[currentUserNamespaceQuery, jest.fn().mockRejectedValueOnce(error)]],
        });
        await showDropdown();

        expect(findAlert().exists()).toBe(true);
      });
    });
  });

  it('displays dropdown placeholder', () => {
    createComponent();

    expect(findDropdown().props('text')).toBe('Select namespace');
  });

  it('displays transfer location as selected', () => {
    const [{ id, full_name: humanName }] = transferLocationsResponsePage1;

    createComponent({
      propsData: {
        value: {
          id,
          humanName,
        },
      },
    });

    expect(findDropdown().props('text')).toBe(humanName);
  });

  describe('when location is selected', () => {
    const groupNamespace = {
      id: transferLocationsResponsePage1[0].id,
      humanName: transferLocationsResponsePage1[0].full_name,
      fullPath: transferLocationsResponsePage1[0].full_path,
    };

    const { namespace: userNamespace } = currentUserNamespaceQueryResponse.data.currentUser;

    describe.each`
      type       | id                                      | value                       | namespacePath   | newPath
      ${'group'} | ${groupNamespace.id}                    | ${groupNamespace.humanName} | ${'my-project'} | ${`${groupNamespace.fullPath}/my-project`}
      ${'group'} | ${groupNamespace.id}                    | ${groupNamespace.humanName} | ${undefined}    | ${undefined}
      ${'user'}  | ${getIdFromGraphQLId(userNamespace.id)} | ${userNamespace.fullName}   | ${'my-project'} | ${`${userNamespace.fullPath}/my-project`}
      ${'user'}  | ${getIdFromGraphQLId(userNamespace.id)} | ${userNamespace.fullName}   | ${undefined}    | ${undefined}
    `('when value is $type', ({ id, value, namespacePath, newPath }) => {
      beforeEach(async () => {
        mockResolvedGetTransferLocations();
        createComponent({ provide: { resourcePath: namespacePath } });
        await showDropdown();

        const dropdownItem = findDropdownItemByText(value);
        dropdownItem.vm.$emit('click');
        await nextTick();
      });

      it('emits selected location with newPath field', () => {
        expect(wrapper.emitted('input')).toHaveLength(1);
        expect(wrapper.emitted('input')[0][0]).toMatchObject({
          id,
          humanName: value,
          newPath,
        });
      });
    });
  });

  describe('when search is typed in', () => {
    const transferLocationsResponseSearch = [transferLocationsResponsePage1[0]];

    const arrange = async ({ propsData, searchTerm } = {}) => {
      mockResolvedGetTransferLocations();
      createComponent({ propsData });
      await showDropdown();
      mockResolvedGetTransferLocations({ data: transferLocationsResponseSearch });
      searchEmitInput(searchTerm);
      await nextTick();
    };

    it('sets `isSearchLoading` prop to `true`', async () => {
      await arrange();

      expect(findSearch().props('isLoading')).toBe(true);
    });

    it('passes `search` param to API call and updates group transfer locations', async () => {
      await arrange();

      await waitForPromises();

      expect(getTransferLocations).toHaveBeenCalledWith(
        resourceId,
        expect.objectContaining({ search: 'foo' }),
      );
      expect(findGroupTransferLocations()).toEqual(
        transferLocationsResponseSearch.map((transferLocation) => transferLocation.full_name),
      );
    });

    it('does not display additional dropdown items if they do not match the search', async () => {
      await arrange({
        propsData: {
          additionalDropdownItems: [additionalDropdownItem],
        },
      });
      await waitForPromises();

      expect(findDropdownItemByText(additionalDropdownItem.humanName)).toBeUndefined();
    });

    it('displays additional dropdown items if they match the search', async () => {
      await arrange({
        propsData: {
          additionalDropdownItems: [additionalDropdownItem],
        },
        searchTerm: 'No par',
      });
      await waitForPromises();

      expect(findDropdownItemByText(additionalDropdownItem.humanName).exists()).toBe(true);
    });
  });

  describe('when enter key is pressed in search', () => {
    beforeEach(async () => {
      createComponent();
      await showDropdown();
    });

    it('prevents default to avoid submitting the form', () => {
      const event = new KeyboardEvent('keydown', {
        key: ENTER_KEY,
      });
      const preventDefaultSpy = jest.spyOn(event, 'preventDefault');
      findSearch().vm.$emit('keydown', event);

      expect(preventDefaultSpy).toHaveBeenCalled();
    });
  });

  describe('when there are no more pages', () => {
    it('does not show intersection observer', async () => {
      mockResolvedGetTransferLocations({
        data: transferLocationsResponsePage1,
        nextPage: null,
        total: '2',
        totalPages: '1',
        prevPage: null,
      });
      createComponent();
      await showDropdown();

      expect(findIntersectionObserver().exists()).toBe(false);
    });
  });

  describe('when intersection observer appears', () => {
    const arrange = async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showDropdown();

      mockResolvedGetTransferLocations({
        data: transferLocationsResponsePage2,
        page: '2',
        nextPage: null,
        prevPage: '1',
        totalPages: '2',
      });

      intersectionObserverEmitAppear();
      await nextTick();
    };

    it('shows loading icon', async () => {
      await arrange();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('passes `page` param to API call', async () => {
      await arrange();

      await waitForPromises();

      expect(getTransferLocations).toHaveBeenCalledWith(
        resourceId,
        expect.objectContaining({ page: 2 }),
      );
    });

    it('updates dropdown with new group transfer locations', async () => {
      await arrange();

      await waitForPromises();

      expect(findGroupTransferLocations()).toEqual(
        [...transferLocationsResponsePage1, ...transferLocationsResponsePage2].map(
          ({ full_name: fullName }) => fullName,
        ),
      );
    });
  });

  it('renders default label', () => {
    createComponent();

    expect(wrapper.findByRole('group', { name: 'Select destination namespace' }).exists()).toBe(
      true,
    );
  });

  describe('when there are no results', () => {
    it('displays no results message', async () => {
      mockResolvedGetTransferLocations({
        data: [],
        page: '1',
        nextPage: null,
        total: '0',
        totalPages: '1',
        prevPage: null,
      });

      createComponent({ propsData: { showUserTransferLocations: false } });

      await showDropdown();

      expect(wrapper.findComponent(GlDropdownItem).text()).toBe(i18n.NO_RESULTS_TEXT);
    });
  });
});
