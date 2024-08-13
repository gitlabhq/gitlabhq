import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { GlEmptyState } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list.vue';
import TagsListRow from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list_row.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import getContainerRepositoryTagsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_tags.query.graphql';
import deleteContainerRepositoryTagsMutation from '~/packages_and_registries/container_registry/explorer/graphql/mutations/delete_container_repository_tags.mutation.graphql';

import {
  GRAPHQL_PAGE_SIZE,
  GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '~/packages_and_registries/container_registry/explorer/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  graphQLDeleteImageRepositoryTagsMock,
  tagsMock,
  imageTagsMock,
  tagsPageInfo,
} from '../../mock_data';
import { DeleteModal } from '../../stubs';

describe('Tags List', () => {
  let wrapper;
  let apolloProvider;
  let resolver;
  const tags = [...tagsMock];

  const defaultConfig = {
    noContainersImage: 'noContainersImage',
  };

  const queryData = {
    first: GRAPHQL_PAGE_SIZE,
    sort: 'NAME_ASC',
    id: '1',
    referrers: true,
  };

  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findPersistedPagination = () => wrapper.findComponent(PersistedPagination);
  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findTagsListRow = () => wrapper.findAllComponents(TagsListRow);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTagsLoader = () => wrapper.findComponent(TagsLoader);

  const mountComponent = ({
    disabled = false,
    showContainerRegistryTagSignatures = true,
    isImageLoading = false,
    mutationResolver,
    config = {},
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getContainerRepositoryTagsQuery, resolver],
      [deleteContainerRepositoryTagsMutation, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = shallowMount(component, {
      apolloProvider,
      propsData: {
        id: 1,
        disabled,
        isImageLoading,
      },
      stubs: { RegistryList, DeleteModal },
      provide() {
        return {
          config: {
            ...defaultConfig,
            ...config,
          },
          glFeatures: { showContainerRegistryTagSignatures },
        };
      },
    });

    findPersistedSearch().vm.$emit('update', { sort: 'NAME_ASC', filters: [], pageInfo: {} });
    return waitForPromises();
  };

  beforeEach(() => {
    resolver = jest.fn().mockResolvedValue(imageTagsMock());
  });

  describe('registry list', () => {
    beforeEach(() => {
      return mountComponent();
    });

    it('has a persisted search', () => {
      expect(findPersistedSearch().props()).toMatchObject({
        defaultOrder: 'NAME',
        defaultSort: 'asc',
        sortableFields: [
          {
            label: 'Name',
            orderBy: 'NAME',
          },
        ],
      });
    });

    it('binds the correct props', () => {
      expect(findRegistryList().props()).toMatchObject({
        title: '4 tags',
        items: tags,
        idProperty: 'name',
        hiddenDelete: false,
      });
    });

    it('has persisted pagination', () => {
      expect(findPersistedPagination().props('pagination')).toEqual(tagsPageInfo);
    });

    describe('events', () => {
      it('prev-page fetches the previous page', async () => {
        findPersistedPagination().vm.$emit('prev');
        await waitForPromises();

        // we are fetching previous page after load,
        // so we expect the resolver to have been called twice
        expect(resolver).toHaveBeenCalledTimes(2);
        expect(resolver).toHaveBeenCalledWith({
          ...queryData,
          first: null,
          before: tagsPageInfo.startCursor,
          last: GRAPHQL_PAGE_SIZE,
        });
      });

      it('next-page fetches the next page', async () => {
        findPersistedPagination().vm.$emit('next');
        await waitForPromises();

        // we are fetching next page after load,
        // so we expect the resolver to have been called twice
        expect(resolver).toHaveBeenCalledTimes(2);
        expect(resolver).toHaveBeenCalledWith({ ...queryData, after: tagsPageInfo.endCursor });
      });

      describe('delete event', () => {
        let trackingSpy;

        beforeEach(() => {
          trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
        });

        afterEach(() => {
          unmockTracking();
        });

        describe('single item', () => {
          beforeEach(() => {
            findRegistryList().vm.$emit('delete', [tags[0]]);
          });

          it('opens the modal', () => {
            expect(DeleteModal.methods.show).toHaveBeenCalled();
          });

          it('sets modal props', () => {
            expect(findDeleteModal().props('itemsToBeDeleted')).toMatchObject([tags[0]]);
          });

          it('tracks a single delete event', () => {
            expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
              label: 'registry_tag_delete',
            });
          });
        });

        describe('multiple items', () => {
          beforeEach(() => {
            findRegistryList().vm.$emit('delete', tags);
          });

          it('opens the modal', () => {
            expect(DeleteModal.methods.show).toHaveBeenCalled();
          });

          it('sets modal props', () => {
            expect(findDeleteModal().props('itemsToBeDeleted')).toMatchObject(tags);
          });

          it('tracks multiple delete event', () => {
            expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
              label: 'bulk_registry_tag_delete',
            });
          });
        });
      });
    });

    describe('when metadata database is enabled', () => {
      beforeEach(() => {
        return mountComponent({
          config: { isMetadataDatabaseEnabled: true },
        });
      });

      it('has persisted search', () => {
        expect(findPersistedSearch().props()).toMatchObject({
          defaultOrder: 'PUBLISHED_AT',
          defaultSort: 'desc',
          sortableFields: [
            {
              label: 'Published',
              orderBy: 'PUBLISHED_AT',
            },
            {
              label: 'Name',
              orderBy: 'NAME',
            },
          ],
        });
      });

      it('increases page size when paginating next', async () => {
        findPersistedPagination().vm.$emit('next');

        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith({
          ...queryData,
          first: GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
          after: tagsPageInfo.endCursor,
        });
      });

      it('increases page size when paginating prev', async () => {
        findPersistedPagination().vm.$emit('prev');

        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith({
          ...queryData,
          first: null,
          last: GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
          before: tagsPageInfo.startCursor,
        });
      });

      it('with before calls resolver with pagination params', async () => {
        findPersistedSearch().vm.$emit('update', {
          sort: 'NAME_ASC',
          filters: [],
          pageInfo: { before: tagsPageInfo.startCursor },
        });

        await waitForPromises();

        expect(resolver).toHaveBeenLastCalledWith({
          ...queryData,
          first: null,
          before: tagsPageInfo.startCursor,
          last: GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
        });
      });

      it('with after calls resolver with pagination params', async () => {
        findPersistedSearch().vm.$emit('update', {
          ...queryData,
          sort: 'NAME_ASC',
          filters: [],
          pageInfo: { after: tagsPageInfo.endCursor },
        });

        await waitForPromises();

        expect(resolver).toHaveBeenLastCalledWith({
          ...queryData,
          first: GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
          after: tagsPageInfo.endCursor,
        });
      });
    });
  });

  describe('when persisted search emits update', () => {
    beforeEach(() => {
      return mountComponent();
    });

    it('with published at sort filter calls resolver with PUBLISHED_AT params', async () => {
      findPersistedSearch().vm.$emit('update', {
        sort: 'PUBLISHED_AT_ASC',
        filters: [],
        pageInfo: {},
      });
      await waitForPromises();

      expect(resolver).toHaveBeenCalledTimes(2);
      expect(resolver).toHaveBeenLastCalledWith({
        ...queryData,
        sort: 'PUBLISHED_AT_ASC',
      });
    });

    it('with filtered-search-term filter calls resolver with name params', async () => {
      findPersistedSearch().vm.$emit('update', {
        sort: 'NAME_ASC',
        filters: [{ id: 'token-1', type: 'filtered-search-term', value: { data: 'gl' } }],
      });
      await waitForPromises();

      expect(resolver).toHaveBeenCalledTimes(2);
      expect(resolver).toHaveBeenLastCalledWith({
        ...queryData,
        name: 'gl',
      });
    });

    it('with before calls resolver with pagination params', async () => {
      findPersistedSearch().vm.$emit('update', {
        sort: 'NAME_ASC',
        filters: [],
        pageInfo: { before: tagsPageInfo.startCursor },
      });
      await waitForPromises();

      expect(resolver).toHaveBeenCalledTimes(2);
      expect(resolver).toHaveBeenLastCalledWith({
        ...queryData,
        first: null,
        before: tagsPageInfo.startCursor,
        last: GRAPHQL_PAGE_SIZE,
      });
    });

    it('with after calls resolver with pagination params', async () => {
      findPersistedSearch().vm.$emit('update', {
        sort: 'NAME_ASC',
        filters: [],
        pageInfo: { after: tagsPageInfo.endCursor },
      });
      await waitForPromises();

      expect(resolver).toHaveBeenCalledTimes(2);
      expect(resolver).toHaveBeenLastCalledWith({
        ...queryData,
        after: tagsPageInfo.endCursor,
      });
    });
  });

  describe('list rows', () => {
    it('one row exist for each tag', async () => {
      await mountComponent();

      expect(findTagsListRow()).toHaveLength(tags.length);
    });

    it('the correct props are bound to it', async () => {
      await mountComponent({ disabled: true });

      const rows = findTagsListRow();

      expect(rows.at(0).attributes()).toMatchObject({
        first: 'true',
        disabled: 'true',
      });
    });

    describe('events', () => {
      it('select event update the selected items', async () => {
        await mountComponent();

        findTagsListRow().at(0).vm.$emit('select');

        await nextTick();

        expect(findTagsListRow().at(0).attributes('selected')).toBe('true');
      });

      describe('delete event', () => {
        let mutationResolver;
        let trackingSpy;

        beforeEach(async () => {
          trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
          mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock);
          resolver = jest.fn().mockResolvedValue(imageTagsMock());
          await mountComponent({ mutationResolver });

          findTagsListRow().at(0).vm.$emit('delete');
        });

        afterEach(() => {
          unmockTracking();
        });

        it('opens the modal', () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('tracks a single delete event', () => {
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });

        it('confirmDelete event calls apollo mutation with the right parameters and refetches the tags list query', async () => {
          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [tags[0].name] }),
          );

          await waitForPromises();

          expect(resolver).toHaveBeenLastCalledWith(queryData);
        });
      });
    });
  });

  describe('when user does not have permission to delete list rows', () => {
    it('sets registry list hiddenDelete prop to true', async () => {
      resolver = jest
        .fn()
        .mockResolvedValue(
          imageTagsMock({ userPermissions: { destroyContainerRepository: false } }),
        );
      await mountComponent();

      expect(findRegistryList().props('hiddenDelete')).toBe(true);
    });
  });

  describe('when the list of tags is empty', () => {
    beforeEach(async () => {
      resolver = jest.fn().mockResolvedValue(imageTagsMock({ nodes: [] }));
      await mountComponent();
    });

    it('does not show the loader', () => {
      expect(findTagsLoader().exists()).toBe(false);
    });

    it('does not show the list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    describe('empty state', () => {
      it('default empty state', () => {
        expect(findEmptyState().props()).toMatchObject({
          svgPath: defaultConfig.noContainersImage,
          title: NO_TAGS_TITLE,
          description: NO_TAGS_MESSAGE,
        });
      });

      it('when filtered shows a filtered message', async () => {
        findPersistedSearch().vm.$emit('update', {
          sort: 'NAME_ASC',
          filters: [{ type: FILTERED_SEARCH_TERM, value: { data: 'foo' } }],
        });

        await waitForPromises();

        expect(findEmptyState().props()).toMatchObject({
          svgPath: defaultConfig.noContainersImage,
          title: NO_TAGS_MATCHING_FILTERS_TITLE,
          description: NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
        });
      });
    });
  });

  describe('delete modal', () => {
    it('exists', async () => {
      await mountComponent();

      expect(findDeleteModal().exists()).toBe(true);
    });

    describe('cancel event', () => {
      let trackingSpy;

      beforeEach(() => {
        trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      it('tracks cancel_delete', async () => {
        await mountComponent();

        findDeleteModal().vm.$emit('cancel');

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'cancel_delete', {
          label: 'registry_tag_delete',
        });
      });
    });

    describe('confirmDelete event', () => {
      let mutationResolver;

      describe('when mutation', () => {
        beforeEach(async () => {
          mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock);
          await mountComponent({ mutationResolver });

          findRegistryList().vm.$emit('delete', [tags[0]]);

          findDeleteModal().vm.$emit('confirmDelete');
        });

        describe('starts', () => {
          beforeEach(async () => {
            await nextTick();
          });

          it('renders loader', () => {
            expect(findTagsLoader().exists()).toBe(true);
            expect(findTagsListRow().exists()).toBe(false);
          });

          it('hides pagination', () => {
            expect(findPersistedPagination().exists()).toEqual(false);
          });
        });

        describe('is resolved', () => {
          beforeEach(async () => {
            await waitForPromises();
          });

          it('loader is hidden', () => {
            expect(findTagsLoader().exists()).toBe(false);
            expect(findTagsListRow().exists()).toBe(true);
          });

          it('pagination is shown', () => {
            expect(findPersistedPagination().props('pagination')).toEqual(tagsPageInfo);
          });
        });
      });

      describe.each([
        {
          description: 'rejection',
          mutationMock: jest.fn().mockRejectedValue(),
        },
        {
          description: 'error',
          mutationMock: jest.fn().mockResolvedValue({
            data: {
              destroyContainerRepositoryTags: {
                errors: [new Error()],
              },
            },
          }),
        },
      ])('when mutation fails with $description', ({ mutationMock }) => {
        beforeEach(() => {
          mutationResolver = mutationMock;
          return mountComponent({ mutationResolver });
        });

        it('when one item is selected to be deleted calls apollo mutation with the right parameters and emits delete event with right arguments', async () => {
          findRegistryList().vm.$emit('delete', [tags[0]]);

          resolver.mockClear();

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [tags[0].name] }),
          );

          expect(resolver).not.toHaveBeenCalled();

          await waitForPromises();

          expect(wrapper.emitted('delete')).toHaveLength(1);
          expect(wrapper.emitted('delete')[0][0]).toEqual('danger_tag');
        });

        it('when more than one item is selected to be deleted calls apollo mutation with the right parameters and emits delete event with right arguments', async () => {
          findRegistryList().vm.$emit('delete', tagsMock);
          resolver.mockClear();

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: tagsMock.map((t) => t.name) }),
          );

          expect(resolver).not.toHaveBeenCalled();

          await waitForPromises();

          expect(wrapper.emitted('delete')).toHaveLength(1);
          expect(wrapper.emitted('delete')[0][0]).toEqual('danger_tags');
        });
      });

      describe('when mutation is successful', () => {
        beforeEach(() => {
          mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock);
          return mountComponent({ mutationResolver });
        });

        it('and one item is selected to be deleted calls apollo mutation with the right parameters and refetches the tags list query', async () => {
          findRegistryList().vm.$emit('delete', [tags[0]]);

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [tags[0].name] }),
          );

          expect(resolver).toHaveBeenLastCalledWith(queryData);

          await waitForPromises();

          expect(wrapper.emitted('delete')).toHaveLength(1);
          expect(wrapper.emitted('delete')[0][0]).toEqual('success_tag');
        });

        it('and more than one item is selected to be deleted calls apollo mutation with the right parameters and refetches the tags list query', async () => {
          findRegistryList().vm.$emit('delete', tagsMock);

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: tagsMock.map((t) => t.name) }),
          );

          expect(resolver).toHaveBeenLastCalledWith(queryData);

          await waitForPromises();

          expect(wrapper.emitted('delete')).toHaveLength(1);
          expect(wrapper.emitted('delete')[0][0]).toEqual('success_tags');
        });
      });
    });
  });

  describe('loading state', () => {
    it.each`
      isImageLoading | queryExecuting | loadingVisible
      ${true}        | ${true}        | ${true}
      ${true}        | ${false}       | ${true}
      ${false}       | ${true}        | ${true}
      ${false}       | ${false}       | ${false}
    `(
      'when the isImageLoading is $isImageLoading, and is $queryExecuting that the query is still executing is $loadingVisible that the loader is shown',
      async ({ isImageLoading, queryExecuting, loadingVisible }) => {
        if (queryExecuting) {
          mountComponent({ isImageLoading });
        } else {
          await mountComponent({ isImageLoading });
        }

        expect(findTagsLoader().exists()).toBe(loadingVisible);
        expect(findTagsListRow().exists()).toBe(!loadingVisible);
        if (queryExecuting) {
          expect(findPersistedPagination().props('pagination')).toEqual({});
        } else {
          expect(findPersistedPagination().props('pagination')).toEqual(tagsPageInfo);
        }
      },
    );
  });

  it('sends referrers as false for the tags query when showContainerRegistryTagSignatures feature flag is off', async () => {
    await mountComponent({ showContainerRegistryTagSignatures: false });

    expect(resolver).toHaveBeenCalledWith({ ...queryData, referrers: false });
  });
});
