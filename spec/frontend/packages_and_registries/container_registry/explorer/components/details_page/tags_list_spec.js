import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { GlEmptyState } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import component from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list.vue';
import TagsListRow from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list_row.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import getContainerRepositoryTagsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_tags.query.graphql';
import {
  GRAPHQL_PAGE_SIZE,
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '~/packages_and_registries/container_registry/explorer/constants/index';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { tagsMock, imageTagsMock, tagsPageInfo } from '../../mock_data';

describe('Tags List', () => {
  let wrapper;
  let apolloProvider;
  let resolver;
  const tags = [...tagsMock];

  const defaultConfig = {
    noContainersImage: 'noContainersImage',
  };

  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findTagsListRow = () => wrapper.findAllComponents(TagsListRow);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTagsLoader = () => wrapper.findComponent(TagsLoader);

  const fireFirstSortUpdate = () => {
    findPersistedSearch().vm.$emit('update', { sort: 'NAME_ASC', filters: [] });
  };

  const waitForApolloRequestRender = async () => {
    await waitForPromises();
    await nextTick();
  };

  const mountComponent = ({ propsData = { isMobile: false, id: 1 } } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[getContainerRepositoryTagsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = shallowMount(component, {
      apolloProvider,
      propsData,
      stubs: { RegistryList },
      provide() {
        return {
          config: defaultConfig,
        };
      },
    });
  };

  beforeEach(() => {
    resolver = jest.fn().mockResolvedValue(imageTagsMock());
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('registry list', () => {
    beforeEach(() => {
      mountComponent();
      fireFirstSortUpdate();
      return waitForApolloRequestRender();
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
        pagination: tagsPageInfo,
        items: tags,
        idProperty: 'name',
      });
    });

    describe('events', () => {
      it('prev-page fetch the previous page', async () => {
        findRegistryList().vm.$emit('prev-page');
        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith({
          first: null,
          name: '',
          sort: 'NAME_ASC',
          before: tagsPageInfo.startCursor,
          last: GRAPHQL_PAGE_SIZE,
          id: '1',
        });
      });

      it('next-page fetch the previous page', async () => {
        findRegistryList().vm.$emit('next-page');
        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith({
          after: tagsPageInfo.endCursor,
          first: GRAPHQL_PAGE_SIZE,
          name: '',
          sort: 'NAME_ASC',
          id: '1',
        });
      });

      it('emits a delete event when list emits delete', () => {
        const eventPayload = 'foo';
        findRegistryList().vm.$emit('delete', eventPayload);

        expect(wrapper.emitted('delete')).toEqual([[eventPayload]]);
      });
    });
  });

  describe('list rows', () => {
    it('one row exist for each tag', async () => {
      mountComponent();
      fireFirstSortUpdate();

      await waitForApolloRequestRender();

      expect(findTagsListRow()).toHaveLength(tags.length);
    });

    it('the correct props are bound to it', async () => {
      mountComponent({ propsData: { disabled: true, id: 1 } });
      fireFirstSortUpdate();

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
        fireFirstSortUpdate();
        await waitForApolloRequestRender();

        findTagsListRow().at(0).vm.$emit('select');

        await nextTick();

        expect(findTagsListRow().at(0).attributes('selected')).toBe('true');
      });

      it('delete event emit a delete event', async () => {
        mountComponent();
        fireFirstSortUpdate();
        await waitForApolloRequestRender();

        findTagsListRow().at(0).vm.$emit('delete');
        expect(wrapper.emitted('delete')[0][0][0].name).toBe(tags[0].name);
      });
    });
  });

  describe('when the list of tags is empty', () => {
    beforeEach(() => {
      resolver = jest.fn().mockResolvedValue(imageTagsMock([]));
      mountComponent();
      fireFirstSortUpdate();
      return waitForApolloRequestRender();
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

        await waitForApolloRequestRender();

        expect(findEmptyState().props()).toMatchObject({
          svgPath: defaultConfig.noContainersImage,
          title: NO_TAGS_MATCHING_FILTERS_TITLE,
          description: NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
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
        fireFirstSortUpdate();
        if (!queryExecuting) {
          await waitForApolloRequestRender();
        }

        expect(findTagsLoader().exists()).toBe(loadingVisible);
        expect(findTagsListRow().exists()).toBe(!loadingVisible);
      },
    );
  });
});
