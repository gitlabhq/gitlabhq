import { GlSkeletonLoader, GlSprintf, GlAlert, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getContainerRepositoriesQuery from 'shared_queries/container_registry/get_container_repositories.query.graphql';
import DeleteImage from '~/packages_and_registries/container_registry/explorer/components/delete_image.vue';
import CliCommands from '~/packages_and_registries/shared/components/cli_commands.vue';
import GroupEmptyState from '~/packages_and_registries/container_registry/explorer/components/list_page/group_empty_state.vue';
import ImageList from '~/packages_and_registries/container_registry/explorer/components/list_page/image_list.vue';
import ProjectEmptyState from '~/packages_and_registries/container_registry/explorer/components/list_page/project_empty_state.vue';
import RegistryHeader from '~/packages_and_registries/container_registry/explorer/components/list_page/registry_header.vue';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  GRAPHQL_PAGE_SIZE,
  GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
  SORT_FIELDS,
  SETTINGS_TEXT,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
} from '~/packages_and_registries/container_registry/explorer/constants';
import deleteContainerRepositoryMutation from '~/packages_and_registries/container_registry/explorer/graphql/mutations/delete_container_repository.mutation.graphql';
import getContainerRepositoriesDetails from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repositories_details.query.graphql';
import component from '~/packages_and_registries/container_registry/explorer/pages/list.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';

import { $toast } from 'jest/packages_and_registries/shared/mocks';
import {
  graphQLImageListMock,
  graphQLImageListNullContainerRepositoriesMock,
  graphQLImageDeleteMock,
  deletedContainerRepository,
  graphQLEmptyImageListMock,
  graphQLEmptyGroupImageListMock,
  graphQLGroupImageListNullContainerRepositoriesMock,
  pageInfo,
  graphQLProjectImageRepositoriesDetailsMock,
  dockerCommands,
} from '../mock_data';
import { GlEmptyState, DeleteModal } from '../stubs';

jest.mock('~/alert');

describe('List Page', () => {
  let wrapper;
  let apolloProvider;

  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const findCliCommands = () => wrapper.findComponent(CliCommands);
  const findSettingsLink = () => wrapper.findComponent(GlButton);
  const findProjectEmptyState = () => wrapper.findComponent(ProjectEmptyState);
  const findGroupEmptyState = () => wrapper.findComponent(GroupEmptyState);
  const findRegistryHeader = () => wrapper.findComponent(RegistryHeader);

  const findDeleteAlert = () => wrapper.findComponent(GlAlert);
  const findMetadataDatabaseAlert = () => wrapper.findComponent(MetadataDatabaseAlert);
  const findImageList = () => wrapper.findComponent(ImageList);
  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findEmptySearchMessage = () => wrapper.find('[data-testid="emptySearch"]');
  const findDeleteImage = () => wrapper.findComponent(DeleteImage);

  const findPersistedPagination = () => wrapper.findComponent(PersistedPagination);

  const fireFirstSortUpdate = () => {
    findPersistedSearch().vm.$emit('update', { sort: 'UPDATED_DESC', filters: [], pageInfo: {} });
  };

  const waitForApolloRequestRender = async () => {
    jest.runOnlyPendingTimers();
    await waitForPromises();
    await nextTick();
  };

  const mountComponent = ({
    mocks,
    resolver = jest.fn().mockResolvedValue(graphQLImageListMock),
    detailsResolver = jest.fn().mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock),
    mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMock),
    config = { isGroupPage: false },
    query = {},
    sortUpdate = false,
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getContainerRepositoriesQuery, resolver],
      [getContainerRepositoriesDetails, detailsResolver],
      [deleteContainerRepositoryMutation, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      apolloProvider,
      stubs: {
        DeleteModal,
        GlEmptyState,
        GlSprintf,
        RegistryHeader,
        TitleArea,
        DeleteImage,
        ImageList,
        MetadataContainerScanning: true,
        ContainerScanningCounts: true,
      },
      mocks: {
        $toast,
        $route: {
          name: 'foo',
          query,
        },
        ...mocks,
      },
      provide() {
        return {
          config,
          ...dockerCommands,
        };
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });

    if (sortUpdate) {
      fireFirstSortUpdate();
    }
  };

  it('contains registry header', async () => {
    mountComponent({ sortUpdate: true });
    await waitForApolloRequestRender();

    expect(findRegistryHeader().exists()).toBe(true);
    expect(findRegistryHeader().props()).toMatchObject({
      imagesCount: 2,
      metadataLoading: false,
      helpPagePath: helpPagePath('user/packages/container_registry/_index'),
      hideExpirationPolicyData: false,
      showCleanupPolicyLink: false,
      expirationPolicy: {},
      cleanupPoliciesSettingsPath: '',
    });
  });

  describe('metadata database alert', () => {
    it('is rendered when metadata database is not enabled', () => {
      mountComponent();

      expect(findMetadataDatabaseAlert().exists()).toBe(true);
    });

    it('is not rendered when metadata database is enabled', () => {
      mountComponent({
        config: {
          isMetadataDatabaseEnabled: true,
        },
      });

      expect(findMetadataDatabaseAlert().exists()).toBe(false);
    });
  });

  describe('link to settings', () => {
    beforeEach(() => {
      const config = {
        showContainerRegistrySettings: true,
        settingsPath: 'bar',
      };
      mountComponent({ config });
    });

    it('is rendered', () => {
      expect(findSettingsLink().exists()).toBe(true);
    });

    it('has the right icon', () => {
      expect(findSettingsLink().props('icon')).toBe('settings');
    });

    it('has the right attributes', () => {
      expect(findSettingsLink().attributes()).toMatchObject({
        'aria-label': SETTINGS_TEXT,
        href: 'bar',
      });
    });

    it('sets tooltip with right label', () => {
      const tooltip = getBinding(findSettingsLink().element, 'gl-tooltip');

      expect(tooltip.value).toBe(SETTINGS_TEXT);
    });
  });

  describe.each([
    { error: 'connectionError', errorName: 'connection error' },
    { error: 'invalidPathError', errorName: 'invalid path error' },
  ])('handling $errorName', ({ error }) => {
    const config = {
      containersErrorImage: 'foo',
      helpPagePath: 'bar',
      isGroupPage: false,
    };
    config[error] = true;

    it('should show an empty state', () => {
      mountComponent({ config });

      expect(findEmptyState().exists()).toBe(true);
    });

    it('empty state should have an svg-path', () => {
      mountComponent({ config });

      expect(findEmptyState().props('svgPath')).toBe(config.containersErrorImage);
    });

    it('empty state should have a description', () => {
      mountComponent({ config });

      expect(findEmptyState().props('title')).toContain('connection error');
    });

    it('should not show the loading or default state', () => {
      mountComponent({ config });

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findImageList().exists()).toBe(false);
    });
  });

  describe('isLoading is true', () => {
    it('shows the skeleton loader', async () => {
      mountComponent({ sortUpdate: true });
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      mountComponent();

      expect(findImageList().exists()).toBe(false);
    });

    it('pagination is set to empty object', () => {
      mountComponent();

      expect(findPersistedPagination().props('pagination')).toEqual({});
    });

    it('cli commands are not visible', () => {
      mountComponent();

      expect(findCliCommands().exists()).toBe(false);
    });

    it('title has the metadataLoading props set to true', async () => {
      mountComponent({ sortUpdate: true });
      await nextTick();

      expect(findRegistryHeader().props('metadataLoading')).toBe(true);
    });
  });

  describe('when mutation is loading', () => {
    beforeEach(async () => {
      mountComponent({ sortUpdate: true });
      await waitForApolloRequestRender();
      findImageList().vm.$emit('delete', deletedContainerRepository);
      findDeleteModal().vm.$emit('confirmDelete');
      findDeleteImage().vm.$emit('start');
    });

    it('shows the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      expect(findImageList().exists()).toBe(false);
    });

    it('pagination is hidden', () => {
      expect(findPersistedPagination().exists()).toBe(false);
    });

    it('cli commands are not visible', () => {
      expect(findCliCommands().exists()).toBe(false);
    });

    it('title has the metadataLoading props set to true', () => {
      expect(findRegistryHeader().props('metadataLoading')).toBe(true);
    });
  });

  describe('list is empty', () => {
    describe('project page', () => {
      const resolver = jest.fn().mockResolvedValue(graphQLEmptyImageListMock);

      beforeEach(async () => {
        mountComponent({ resolver, sortUpdate: true });
        await waitForApolloRequestRender();
      });

      it('cli commands are not visible', () => {
        expect(findCliCommands().exists()).toBe(false);
      });

      it('project empty state is visible', () => {
        expect(findProjectEmptyState().exists()).toBe(true);
      });
    });

    describe('group page', () => {
      const resolver = jest.fn().mockResolvedValue(graphQLEmptyGroupImageListMock);

      const config = {
        isGroupPage: true,
      };

      beforeEach(async () => {
        mountComponent({ resolver, config, sortUpdate: true });
        await waitForApolloRequestRender();
      });

      it('group empty state is visible', () => {
        expect(findGroupEmptyState().exists()).toBe(true);
      });

      it('cli commands are not visible', () => {
        expect(findCliCommands().exists()).toBe(false);
      });

      it('link to settings is not visible', () => {
        expect(findSettingsLink().exists()).toBe(false);
      });
    });
  });

  describe('GraphQL query returns null', () => {
    describe.each`
      pageType     | config                    | response                                              | emptyStateFinder
      ${'project'} | ${{ isGroupPage: false }} | ${graphQLImageListNullContainerRepositoriesMock}      | ${findProjectEmptyState}
      ${'group'}   | ${{ isGroupPage: true }}  | ${graphQLGroupImageListNullContainerRepositoriesMock} | ${findGroupEmptyState}
    `('$pageType page', ({ pageType, config, response, emptyStateFinder }) => {
      beforeEach(async () => {
        mountComponent({
          config,
          detailsResolver: jest.fn().mockResolvedValue(response),
          resolver: jest.fn().mockResolvedValue(response),
          sortUpdate: true,
        });
        await waitForApolloRequestRender();
      });

      it('cli commands are not visible', () => {
        expect(findCliCommands().exists()).toBe(false);
      });

      it(`${pageType} empty state is visible`, () => {
        expect(emptyStateFinder().exists()).toBe(true);
      });

      it('createAlert is not called', () => {
        expect(createAlert).not.toHaveBeenCalledWith({
          message: FETCH_IMAGES_LIST_ERROR_MESSAGE,
        });
      });
    });
  });

  describe('list is not empty', () => {
    describe('unfiltered state', () => {
      it('quick start is visible', async () => {
        mountComponent({ sortUpdate: true });
        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(true);
      });

      it('list component is visible', async () => {
        mountComponent({ sortUpdate: true });
        await waitForApolloRequestRender();

        expect(findImageList().exists()).toBe(true);
      });

      describe('additional metadata', () => {
        it('is called on component load', async () => {
          const detailsResolver = jest
            .fn()
            .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
          mountComponent({ detailsResolver, sortUpdate: true });
          jest.runOnlyPendingTimers();
          await waitForPromises();

          expect(detailsResolver).toHaveBeenCalled();
        });

        it('does not block the list ui to show', async () => {
          const detailsResolver = jest.fn().mockRejectedValue();
          mountComponent({ detailsResolver, sortUpdate: true });
          await waitForApolloRequestRender();

          expect(findImageList().exists()).toBe(true);
        });

        it('loading state is passed to list component', async () => {
          // this is a promise that never resolves, to trick apollo to think that this request is still loading
          const detailsResolver = jest.fn().mockImplementation(() => new Promise(() => {}));

          mountComponent({ detailsResolver, sortUpdate: true });
          await waitForApolloRequestRender();

          expect(findImageList().props('metadataLoading')).toBe(true);
        });
      });

      describe('delete image', () => {
        const selectImageForDeletion = async () => {
          fireFirstSortUpdate();
          await waitForApolloRequestRender();

          findImageList().vm.$emit('delete', deletedContainerRepository);
        };

        it('should call deleteItem when confirming deletion', async () => {
          const mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMock);
          mountComponent({ mutationResolver });

          await selectImageForDeletion();

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith({ id: deletedContainerRepository.id });
        });

        it('should show a success alert when delete request is successful', async () => {
          mountComponent();

          await selectImageForDeletion();

          findDeleteImage().vm.$emit('success');
          await nextTick();

          const alert = findDeleteAlert();
          expect(alert.exists()).toBe(true);
          expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
            DELETE_IMAGE_SUCCESS_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
          );
        });

        describe('when delete request fails it shows an alert', () => {
          it('user recoverable error', async () => {
            mountComponent();

            await selectImageForDeletion();

            findDeleteImage().vm.$emit('error');
            await nextTick();

            const alert = findDeleteAlert();
            expect(alert.exists()).toBe(true);
            expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
              DELETE_IMAGE_ERROR_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
            );
          });
        });
      });
    });

    describe('search and sorting', () => {
      const doSearch = async () => {
        await waitForApolloRequestRender();
        findPersistedSearch().vm.$emit('update', {
          sort: 'UPDATED_DESC',
          filters: [{ type: FILTERED_SEARCH_TERM, value: { data: 'centos6' } }],
        });

        findPersistedSearch().vm.$emit('filter:submit');

        await waitForPromises();
      };

      it('has a persisted search box element', async () => {
        mountComponent({ sortUpdate: true });
        await waitForApolloRequestRender();

        const registrySearch = findPersistedSearch();
        expect(registrySearch.exists()).toBe(true);
        expect(registrySearch.props()).toMatchObject({
          defaultOrder: 'UPDATED',
          defaultSort: 'desc',
          sortableFields: SORT_FIELDS,
        });
      });

      it('performs sorting', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        findPersistedSearch().vm.$emit('update', { sort: 'UPDATED_DESC', filters: [] });
        await nextTick();

        expect(resolver).toHaveBeenCalledWith(expect.objectContaining({ sort: 'UPDATED_DESC' }));
      });

      it('performs a search', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        await doSearch();

        expect(resolver).toHaveBeenCalledWith(expect.objectContaining({ name: 'centos6' }));
      });

      it('when search result is empty displays an empty search message', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver });

        await waitForApolloRequestRender();

        resolver.mockResolvedValue(graphQLEmptyImageListMock);
        detailsResolver.mockResolvedValue(graphQLEmptyImageListMock);

        await doSearch();

        expect(findEmptySearchMessage().exists()).toBe(true);
      });
    });

    describe('pagination', () => {
      it('exists', async () => {
        mountComponent({ sortUpdate: true });
        await waitForApolloRequestRender();

        expect(findPersistedPagination().props('pagination')).toEqual(pageInfo);
      });

      it('prev event triggers a previous page request', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver, sortUpdate: true });
        await waitForApolloRequestRender();

        findPersistedPagination().vm.$emit('prev');
        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({
            before: pageInfo.startCursor,
            first: null,
            last: GRAPHQL_PAGE_SIZE,
          }),
        );
        expect(detailsResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            before: pageInfo.startCursor,
            first: null,
            last: GRAPHQL_PAGE_SIZE,
          }),
        );
      });

      it('calls resolver with pagination params when persisted search returns before', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver });

        findPersistedSearch().vm.$emit('update', {
          sort: 'UPDATED_DESC',
          filters: [],
          pageInfo: { before: pageInfo.startCursor },
        });
        await waitForApolloRequestRender();

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({
            sort: 'UPDATED_DESC',
            before: pageInfo.startCursor,
            first: null,
            last: GRAPHQL_PAGE_SIZE,
          }),
        );
        expect(detailsResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            sort: 'UPDATED_DESC',
            before: pageInfo.startCursor,
            first: null,
            last: GRAPHQL_PAGE_SIZE,
          }),
        );
      });

      it('next event triggers a next page request', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver, sortUpdate: true });
        await waitForApolloRequestRender();

        findPersistedPagination().vm.$emit('next');
        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({
            after: pageInfo.endCursor,
            first: GRAPHQL_PAGE_SIZE,
          }),
        );
        expect(detailsResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            after: pageInfo.endCursor,
            first: GRAPHQL_PAGE_SIZE,
          }),
        );
      });

      it('calls resolver with pagination params when persisted search returns after', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver });

        findPersistedSearch().vm.$emit('update', {
          sort: 'UPDATED_DESC',
          filters: [],
          pageInfo: { after: pageInfo.endCursor },
        });
        await waitForApolloRequestRender();

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({
            sort: 'UPDATED_DESC',
            after: pageInfo.endCursor,
            first: GRAPHQL_PAGE_SIZE,
          }),
        );
        expect(detailsResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            sort: 'UPDATED_DESC',
            after: pageInfo.endCursor,
            first: GRAPHQL_PAGE_SIZE,
          }),
        );
      });

      describe('with metadata database enabled', () => {
        it.each`
          event     | expected
          ${'prev'} | ${{ before: pageInfo.startCursor, first: null, last: GRAPHQL_PAGE_SIZE_METADATA_ENABLED }}
          ${'next'} | ${{ after: pageInfo.endCursor, first: GRAPHQL_PAGE_SIZE_METADATA_ENABLED }}
        `('$event event triggers correct page request', async ({ event, expected }) => {
          const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
          const detailsResolver = jest
            .fn()
            .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
          const config = {
            isMetadataDatabaseEnabled: true,
            isGroupPage: false,
          };

          mountComponent({ resolver, detailsResolver, config, sortUpdate: true });
          await waitForApolloRequestRender();

          findPersistedPagination().vm.$emit(event);
          await waitForPromises();

          expect(resolver).toHaveBeenCalledWith(expect.objectContaining(expected));
          expect(detailsResolver).toHaveBeenCalledWith(expect.objectContaining(expected));
        });

        it.each`
          cursor                              | expected
          ${{ before: pageInfo.startCursor }} | ${{ sort: 'UPDATED_DESC', before: pageInfo.startCursor, first: null, last: GRAPHQL_PAGE_SIZE_METADATA_ENABLED }}
          ${{ after: pageInfo.endCursor }}    | ${{ sort: 'UPDATED_DESC', after: pageInfo.endCursor, first: GRAPHQL_PAGE_SIZE_METADATA_ENABLED }}
        `(
          'calls resolver correctly when persisted search returns $cursor',
          async ({ cursor, expected }) => {
            const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
            const detailsResolver = jest
              .fn()
              .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
            const config = {
              isMetadataDatabaseEnabled: true,
              isGroupPage: false,
            };

            mountComponent({ resolver, detailsResolver, config });

            findPersistedSearch().vm.$emit('update', {
              sort: 'UPDATED_DESC',
              filters: [],
              pageInfo: cursor,
            });
            await waitForApolloRequestRender();

            expect(resolver).toHaveBeenCalledWith(expect.objectContaining(expected));
            expect(detailsResolver).toHaveBeenCalledWith(expect.objectContaining(expected));
          },
        );
      });
    });
  });

  describe('modal', () => {
    beforeEach(() => {
      mountComponent({ sortUpdate: true });
    });

    it('exists', () => {
      expect(findDeleteModal().exists()).toBe(true);
    });

    it('contains the deleted image as props', async () => {
      await waitForPromises();
      findImageList().vm.$emit('delete', deletedContainerRepository);
      await nextTick();

      expect(findDeleteModal().props()).toEqual({
        itemsToBeDeleted: [deletedContainerRepository],
        deleteImage: true,
      });
    });
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      mountComponent({ sortUpdate: true });
    });

    afterEach(() => {
      unmockTracking();
    });

    const testTrackingCall = (action) => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, action, {
        label: 'registry_repository_delete',
      });
    };

    it('send an event when delete button is clicked', async () => {
      await waitForPromises();
      findImageList().vm.$emit('delete', {});

      testTrackingCall('click_button');
    });

    it('send an event when cancel is pressed on modal', () => {
      const deleteModal = findDeleteModal();
      deleteModal.vm.$emit('cancel');
      testTrackingCall('cancel_delete');
    });

    it('send an event when the deletion starts', () => {
      findDeleteImage().vm.$emit('start');
      testTrackingCall('confirm_delete');
    });
  });
});
