import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stripTypenames } from 'helpers/graphql_helpers';
import EmptyTagsState from '~/packages_and_registries/container_registry/explorer/components/details_page/empty_state.vue';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list.vue';
import TagsListRow from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list_row.vue';
import TagsLoader from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import getContainerRepositoryTagsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_tags.query.graphql';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/container_registry/explorer/constants/index';
import { tagsMock, imageTagsMock, tagsPageInfo } from '../../mock_data';

const localVue = createLocalVue();

describe('Tags List', () => {
  let wrapper;
  let apolloProvider;
  let resolver;
  const tags = [...tagsMock];

  const findTagsListRow = () => wrapper.findAllComponents(TagsListRow);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findComponent(EmptyTagsState);
  const findTagsLoader = () => wrapper.findComponent(TagsLoader);

  const waitForApolloRequestRender = async () => {
    await waitForPromises();
    await nextTick();
  };

  const mountComponent = ({ propsData = { isMobile: false, id: 1 } } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [[getContainerRepositoryTagsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      propsData,
      stubs: { RegistryList },
      provide() {
        return {
          config: {},
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

      return waitForApolloRequestRender();
    });

    it('binds the correct props', () => {
      expect(findRegistryList().props()).toMatchObject({
        title: '2 tags',
        pagination: stripTypenames(tagsPageInfo),
        items: stripTypenames(tags),
        idProperty: 'name',
      });
    });

    describe('events', () => {
      it('prev-page fetch the previous page', () => {
        findRegistryList().vm.$emit('prev-page');

        expect(resolver).toHaveBeenCalledWith({
          first: null,
          before: tagsPageInfo.startCursor,
          last: GRAPHQL_PAGE_SIZE,
          id: '1',
        });
      });

      it('next-page fetch the previous page', () => {
        findRegistryList().vm.$emit('next-page');

        expect(resolver).toHaveBeenCalledWith({
          after: tagsPageInfo.endCursor,
          first: GRAPHQL_PAGE_SIZE,
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

      it('delete event emit a delete event', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        findTagsListRow().at(0).vm.$emit('delete');
        expect(wrapper.emitted('delete')[0][0][0].name).toBe(tags[0].name);
      });
    });
  });

  describe('when the list of tags is empty', () => {
    beforeEach(() => {
      resolver = jest.fn().mockResolvedValue(imageTagsMock([]));
    });

    it('has the empty state', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show the loader', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findTagsLoader().exists()).toBe(false);
    });

    it('does not show the list', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findRegistryList().exists()).toBe(false);
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
      },
    );
  });
});
