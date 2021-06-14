import { GlSkeletonLoader, GlSprintf, GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getContainerRepositoriesQuery from 'shared_queries/container_registry/get_container_repositories.query.graphql';
import CleanupPolicyEnabledAlert from '~/packages_and_registries/shared/components/cleanup_policy_enabled_alert.vue';
import { FILTERED_SEARCH_TERM } from '~/packages_and_registries/shared/constants';
import DeleteImage from '~/registry/explorer/components/delete_image.vue';
import CliCommands from '~/registry/explorer/components/list_page/cli_commands.vue';
import GroupEmptyState from '~/registry/explorer/components/list_page/group_empty_state.vue';
import ImageList from '~/registry/explorer/components/list_page/image_list.vue';
import ProjectEmptyState from '~/registry/explorer/components/list_page/project_empty_state.vue';
import RegistryHeader from '~/registry/explorer/components/list_page/registry_header.vue';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  SORT_FIELDS,
} from '~/registry/explorer/constants';
import deleteContainerRepositoryMutation from '~/registry/explorer/graphql/mutations/delete_container_repository.mutation.graphql';
import getContainerRepositoriesDetails from '~/registry/explorer/graphql/queries/get_container_repositories_details.query.graphql';
import component from '~/registry/explorer/pages/list.vue';
import Tracking from '~/tracking';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

import { $toast } from '../../shared/mocks';
import {
  graphQLImageListMock,
  graphQLImageDeleteMock,
  deletedContainerRepository,
  graphQLEmptyImageListMock,
  graphQLEmptyGroupImageListMock,
  pageInfo,
  graphQLProjectImageRepositoriesDetailsMock,
  dockerCommands,
} from '../mock_data';
import { GlModal, GlEmptyState } from '../stubs';

const localVue = createLocalVue();

describe('List Page', () => {
  let wrapper;
  let apolloProvider;

  const findDeleteModal = () => wrapper.findComponent(GlModal);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const findCliCommands = () => wrapper.findComponent(CliCommands);
  const findProjectEmptyState = () => wrapper.findComponent(ProjectEmptyState);
  const findGroupEmptyState = () => wrapper.findComponent(GroupEmptyState);
  const findRegistryHeader = () => wrapper.findComponent(RegistryHeader);

  const findDeleteAlert = () => wrapper.findComponent(GlAlert);
  const findImageList = () => wrapper.findComponent(ImageList);
  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findEmptySearchMessage = () => wrapper.find('[data-testid="emptySearch"]');
  const findDeleteImage = () => wrapper.findComponent(DeleteImage);
  const findCleanupAlert = () => wrapper.findComponent(CleanupPolicyEnabledAlert);

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
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getContainerRepositoriesQuery, resolver],
      [getContainerRepositoriesDetails, detailsResolver],
      [deleteContainerRepositoryMutation, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      stubs: {
        GlModal,
        GlEmptyState,
        GlSprintf,
        RegistryHeader,
        TitleArea,
        DeleteImage,
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
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains registry header', async () => {
    mountComponent();

    await waitForApolloRequestRender();

    expect(findRegistryHeader().exists()).toBe(true);
    expect(findRegistryHeader().props()).toMatchObject({
      imagesCount: 2,
      metadataLoading: false,
    });
  });

  describe('connection error', () => {
    const config = {
      characterError: true,
      containersErrorImage: 'foo',
      helpPagePath: 'bar',
      isGroupPage: false,
    };

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
      mountComponent();

      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      mountComponent();

      expect(findImageList().exists()).toBe(false);
    });

    it('cli commands is not visible', () => {
      mountComponent();

      expect(findCliCommands().exists()).toBe(false);
    });

    it('title has the metadataLoading props set to true', async () => {
      mountComponent();

      await nextTick();

      expect(findRegistryHeader().props('metadataLoading')).toBe(true);
    });
  });

  describe('list is empty', () => {
    describe('project page', () => {
      const resolver = jest.fn().mockResolvedValue(graphQLEmptyImageListMock);

      it('cli commands is not visible', async () => {
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(false);
      });

      it('project empty state is visible', async () => {
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        expect(findProjectEmptyState().exists()).toBe(true);
      });
    });

    describe('group page', () => {
      const resolver = jest.fn().mockResolvedValue(graphQLEmptyGroupImageListMock);

      const config = {
        isGroupPage: true,
      };

      it('group empty state is visible', async () => {
        mountComponent({ resolver, config });

        await waitForApolloRequestRender();

        expect(findGroupEmptyState().exists()).toBe(true);
      });

      it('cli commands is not visible', async () => {
        mountComponent({ resolver, config });

        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(false);
      });
    });
  });

  describe('list is not empty', () => {
    describe('unfiltered state', () => {
      it('quick start is visible', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(true);
      });

      it('list component is visible', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        expect(findImageList().exists()).toBe(true);
      });

      describe('additional metadata', () => {
        it('is called on component load', async () => {
          const detailsResolver = jest
            .fn()
            .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
          mountComponent({ detailsResolver });

          jest.runOnlyPendingTimers();
          await waitForPromises();

          expect(detailsResolver).toHaveBeenCalled();
        });

        it('does not block the list ui to show', async () => {
          const detailsResolver = jest.fn().mockRejectedValue();
          mountComponent({ detailsResolver });

          await waitForApolloRequestRender();

          expect(findImageList().exists()).toBe(true);
        });

        it('loading state is passed to list component', async () => {
          // this is a promise that never resolves, to trick apollo to think that this request is still loading
          const detailsResolver = jest.fn().mockImplementation(() => new Promise(() => {}));

          mountComponent({ detailsResolver });
          await waitForApolloRequestRender();

          expect(findImageList().props('metadataLoading')).toBe(true);
        });
      });

      describe('delete image', () => {
        const selectImageForDeletion = async () => {
          await waitForApolloRequestRender();

          findImageList().vm.$emit('delete', deletedContainerRepository);
        };

        it('should call deleteItem when confirming deletion', async () => {
          const mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMock);
          mountComponent({ mutationResolver });

          await selectImageForDeletion();

          findDeleteModal().vm.$emit('primary');
          await waitForApolloRequestRender();

          expect(wrapper.vm.itemToDelete).toEqual(deletedContainerRepository);

          const updatedImage = findImageList()
            .props('images')
            .find((i) => i.id === deletedContainerRepository.id);

          expect(updatedImage.status).toBe(deletedContainerRepository.status);
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
        findRegistrySearch().vm.$emit('filter:changed', [
          { type: FILTERED_SEARCH_TERM, value: { data: 'centos6' } },
        ]);

        findRegistrySearch().vm.$emit('filter:submit');

        await nextTick();
      };

      it('has a search box element', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        const registrySearch = findRegistrySearch();
        expect(registrySearch.exists()).toBe(true);
        expect(registrySearch.props()).toMatchObject({
          filter: [],
          sorting: { orderBy: 'UPDATED', sort: 'desc' },
          sortableFields: SORT_FIELDS,
          tokens: [],
        });
      });

      it('performs sorting', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        findRegistrySearch().vm.$emit('sorting:changed', { sort: 'asc' });
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
      it('prev-page event triggers a fetchMore request', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver });

        await waitForApolloRequestRender();

        findImageList().vm.$emit('prev-page');
        await nextTick();

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({ before: pageInfo.startCursor }),
        );
        expect(detailsResolver).toHaveBeenCalledWith(
          expect.objectContaining({ before: pageInfo.startCursor }),
        );
      });

      it('next-page event triggers a fetchMore request', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        const detailsResolver = jest
          .fn()
          .mockResolvedValue(graphQLProjectImageRepositoriesDetailsMock);
        mountComponent({ resolver, detailsResolver });

        await waitForApolloRequestRender();

        findImageList().vm.$emit('next-page');
        await nextTick();

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({ after: pageInfo.endCursor }),
        );
        expect(detailsResolver).toHaveBeenCalledWith(
          expect.objectContaining({ after: pageInfo.endCursor }),
        );
      });
    });
  });

  describe('modal', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findDeleteModal().exists()).toBe(true);
    });

    it('contains a description with the path of the item to delete', async () => {
      findImageList().vm.$emit('delete', { path: 'foo' });
      await nextTick();
      expect(findDeleteModal().html()).toContain('foo');
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      mountComponent();
    });

    const testTrackingCall = (action) => {
      expect(Tracking.event).toHaveBeenCalledWith(undefined, action, {
        label: 'registry_repository_delete',
      });
    };

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
    });

    it('send an event when delete button is clicked', () => {
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

  describe('url query string handling', () => {
    const defaultQueryParams = {
      search: [1, 2],
      sort: 'asc',
      orderBy: 'CREATED',
    };
    const queryChangePayload = 'foo';

    it('query:updated event pushes the new query to the router', async () => {
      const push = jest.fn();
      mountComponent({ mocks: { $router: { push } } });

      await nextTick();

      findRegistrySearch().vm.$emit('query:changed', queryChangePayload);

      expect(push).toHaveBeenCalledWith({ query: queryChangePayload });
    });

    it('graphql API call has the variables set from the URL', async () => {
      const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
      mountComponent({ query: defaultQueryParams, resolver });

      await nextTick();

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 1,
          sort: 'CREATED_ASC',
        }),
      );
    });

    it.each`
      sort         | orderBy      | search            | payload
      ${'ASC'}     | ${undefined} | ${undefined}      | ${{ sort: 'UPDATED_ASC' }}
      ${undefined} | ${'bar'}     | ${undefined}      | ${{ sort: 'BAR_DESC' }}
      ${'ASC'}     | ${'bar'}     | ${undefined}      | ${{ sort: 'BAR_ASC' }}
      ${undefined} | ${undefined} | ${undefined}      | ${{}}
      ${undefined} | ${undefined} | ${['one']}        | ${{ name: 'one' }}
      ${undefined} | ${undefined} | ${['one', 'two']} | ${{ name: 'one' }}
      ${undefined} | ${'UPDATED'} | ${['one', 'two']} | ${{ name: 'one', sort: 'UPDATED_DESC' }}
      ${'ASC'}     | ${'UPDATED'} | ${['one', 'two']} | ${{ name: 'one', sort: 'UPDATED_ASC' }}
    `(
      'with sort equal to $sort, orderBy equal to $orderBy, search set to $search API call has the variables set as $payload',
      async ({ sort, orderBy, search, payload }) => {
        const resolver = jest.fn().mockResolvedValue({ sort, orderBy });
        mountComponent({ query: { sort, orderBy, search }, resolver });

        await nextTick();

        expect(resolver).toHaveBeenCalledWith(expect.objectContaining(payload));
      },
    );
  });

  describe('cleanup is on alert', () => {
    it('exist when showCleanupPolicyOnAlert is true and has the correct props', async () => {
      mountComponent({
        config: {
          showCleanupPolicyOnAlert: true,
          projectPath: 'foo',
          isGroupPage: false,
          cleanupPoliciesSettingsPath: 'bar',
        },
      });

      await waitForApolloRequestRender();

      expect(findCleanupAlert().exists()).toBe(true);
      expect(findCleanupAlert().props()).toMatchObject({
        projectPath: 'foo',
        cleanupPoliciesSettingsPath: 'bar',
      });
    });

    it('is hidden when showCleanupPolicyOnAlert is false', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findCleanupAlert().exists()).toBe(false);
    });
  });
});
