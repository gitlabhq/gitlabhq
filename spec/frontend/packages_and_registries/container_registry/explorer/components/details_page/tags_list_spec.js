import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { GlEmptyState } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Tracking from '~/tracking';
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
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '~/packages_and_registries/container_registry/explorer/constants/index';
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

  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findPersistedPagination = () => wrapper.findComponent(PersistedPagination);
  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findTagsListRow = () => wrapper.findAllComponents(TagsListRow);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTagsLoader = () => wrapper.findComponent(TagsLoader);

  const fireFirstSortUpdate = () => {
    findPersistedSearch().vm.$emit('update', { sort: 'NAME_ASC', filters: [], pageInfo: {} });
  };

  const waitForApolloRequestRender = async () => {
    fireFirstSortUpdate();
    await waitForPromises();
  };

  const mountComponent = ({ propsData = { isMobile: false, id: 1 }, mutationResolver } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getContainerRepositoryTagsQuery, resolver],
      [deleteContainerRepositoryTagsMutation, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = shallowMount(component, {
      apolloProvider,
      propsData,
      stubs: { RegistryList, DeleteModal },
      provide() {
        return {
          config: defaultConfig,
        };
      },
    });
  };

  beforeEach(() => {
    resolver = jest.fn().mockResolvedValue(imageTagsMock());
    jest.spyOn(Tracking, 'event');
  });

  describe('registry list', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForApolloRequestRender();
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
        title: '2 tags',
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
          first: null,
          name: '',
          sort: 'NAME_ASC',
          before: tagsPageInfo.startCursor,
          last: GRAPHQL_PAGE_SIZE,
          id: '1',
        });
      });

      it('next-page fetches the next page', async () => {
        findPersistedPagination().vm.$emit('next');
        await waitForPromises();

        // we are fetching next page after load,
        // so we expect the resolver to have been called twice
        expect(resolver).toHaveBeenCalledTimes(2);
        expect(resolver).toHaveBeenCalledWith({
          after: tagsPageInfo.endCursor,
          first: GRAPHQL_PAGE_SIZE,
          name: '',
          sort: 'NAME_ASC',
          id: '1',
        });
      });

      describe('delete event', () => {
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
            expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
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
            expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
              label: 'bulk_registry_tag_delete',
            });
          });
        });
      });
    });
  });

  describe('when persisted search emits update', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('with before calls resolver with pagination params', async () => {
      findPersistedSearch().vm.$emit('update', {
        sort: 'NAME_ASC',
        filters: [],
        pageInfo: { before: tagsPageInfo.startCursor },
      });
      await waitForPromises();

      expect(resolver).toHaveBeenCalledTimes(1);
      expect(resolver).toHaveBeenCalledWith({
        first: null,
        name: '',
        sort: 'NAME_ASC',
        before: tagsPageInfo.startCursor,
        last: GRAPHQL_PAGE_SIZE,
        id: '1',
      });
    });

    it('with after calls resolver with pagination params', async () => {
      findPersistedSearch().vm.$emit('update', {
        sort: 'NAME_ASC',
        filters: [],
        pageInfo: { after: tagsPageInfo.endCursor },
      });
      await waitForPromises();

      expect(resolver).toHaveBeenCalledTimes(1);
      expect(resolver).toHaveBeenCalledWith({
        after: tagsPageInfo.endCursor,
        first: GRAPHQL_PAGE_SIZE,
        name: '',
        sort: 'NAME_ASC',
        id: '1',
      });
    });
  });

  describe('list rows', () => {
    it('one row exist for each tag', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findTagsListRow()).toHaveLength(tags.length);
    });

    it('the correct props are bound to it', async () => {
      mountComponent({ propsData: { disabled: true, id: 1 } });

      await waitForApolloRequestRender();

      const rows = findTagsListRow();

      expect(rows.at(0).attributes()).toMatchObject({
        first: 'true',
        disabled: 'true',
      });
    });

    describe('events', () => {
      it('select event update the selected items', async () => {
        mountComponent();
        await waitForApolloRequestRender();

        findTagsListRow().at(0).vm.$emit('select');

        await nextTick();

        expect(findTagsListRow().at(0).attributes('selected')).toBe('true');
      });

      describe('delete event', () => {
        let mutationResolver;

        beforeEach(async () => {
          mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock);
          resolver = jest.fn().mockResolvedValue(imageTagsMock());
          mountComponent({ mutationResolver });

          await waitForApolloRequestRender();
          findTagsListRow().at(0).vm.$emit('delete');
        });

        it('opens the modal', () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('tracks a single delete event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });

        it('confirmDelete event calls apollo mutation with the right parameters and refetches the tags list query', async () => {
          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [tags[0].name] }),
          );

          await waitForPromises();

          expect(resolver).toHaveBeenLastCalledWith({
            first: GRAPHQL_PAGE_SIZE,
            name: '',
            sort: 'NAME_ASC',
            id: '1',
          });
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
      mountComponent();
      await waitForApolloRequestRender();

      expect(findRegistryList().props('hiddenDelete')).toBe(true);
    });
  });

  describe('when the list of tags is empty', () => {
    beforeEach(async () => {
      resolver = jest.fn().mockResolvedValue(imageTagsMock({ nodes: [] }));
      mountComponent();
      await waitForApolloRequestRender();
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

  describe('modal', () => {
    it('exists', async () => {
      mountComponent();
      await waitForApolloRequestRender();

      expect(findDeleteModal().exists()).toBe(true);
    });

    describe('cancel event', () => {
      it('tracks cancel_delete', async () => {
        mountComponent();
        await waitForApolloRequestRender();

        findDeleteModal().vm.$emit('cancel');

        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'cancel_delete', {
          label: 'registry_tag_delete',
        });
      });
    });

    describe('confirmDelete event', () => {
      let mutationResolver;

      describe('when mutation', () => {
        beforeEach(async () => {
          mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock);
          mountComponent({ mutationResolver });

          await waitForApolloRequestRender();
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
          mountComponent({ mutationResolver });

          return waitForApolloRequestRender();
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
          mountComponent({ mutationResolver });

          return waitForApolloRequestRender();
        });

        it('and one item is selected to be deleted calls apollo mutation with the right parameters and refetches the tags list query', async () => {
          findRegistryList().vm.$emit('delete', [tags[0]]);

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [tags[0].name] }),
          );

          expect(resolver).toHaveBeenLastCalledWith({
            first: GRAPHQL_PAGE_SIZE,
            name: '',
            sort: 'NAME_ASC',
            id: '1',
          });

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

          expect(resolver).toHaveBeenLastCalledWith({
            first: GRAPHQL_PAGE_SIZE,
            name: '',
            sort: 'NAME_ASC',
            id: '1',
          });

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
        mountComponent({ propsData: { isImageLoading, isMobile: false, id: 1 } });
        if (!queryExecuting) {
          await waitForApolloRequestRender();
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
});
