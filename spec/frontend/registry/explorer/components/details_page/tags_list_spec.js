import { GlButton, GlKeysetPagination } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EmptyTagsState from '~/registry/explorer/components/details_page/empty_state.vue';
import component from '~/registry/explorer/components/details_page/tags_list.vue';
import TagsListRow from '~/registry/explorer/components/details_page/tags_list_row.vue';
import TagsLoader from '~/registry/explorer/components/details_page/tags_loader.vue';
import { TAGS_LIST_TITLE, REMOVE_TAGS_BUTTON_TITLE } from '~/registry/explorer/constants/index';
import getContainerRepositoryTagsQuery from '~/registry/explorer/graphql/queries/get_container_repository_tags.query.graphql';
import { tagsMock, imageTagsMock, tagsPageInfo } from '../../mock_data';

const localVue = createLocalVue();

describe('Tags List', () => {
  let wrapper;
  let apolloProvider;
  const tags = [...tagsMock];
  const readOnlyTags = tags.map((t) => ({ ...t, canDelete: false }));

  const findTagsListRow = () => wrapper.findAll(TagsListRow);
  const findDeleteButton = () => wrapper.find(GlButton);
  const findListTitle = () => wrapper.find('[data-testid="list-title"]');
  const findPagination = () => wrapper.find(GlKeysetPagination);
  const findEmptyState = () => wrapper.find(EmptyTagsState);
  const findTagsLoader = () => wrapper.find(TagsLoader);

  const waitForApolloRequestRender = async () => {
    await waitForPromises();
    await nextTick();
  };

  const mountComponent = ({
    propsData = { isMobile: false, id: 1 },
    resolver = jest.fn().mockResolvedValue(imageTagsMock()),
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [[getContainerRepositoryTagsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      propsData,
      provide() {
        return {
          config: {},
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('List title', () => {
    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findListTitle().exists()).toBe(true);
    });

    it('has the correct text', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findListTitle().text()).toBe(TAGS_LIST_TITLE);
    });
  });

  describe('delete button', () => {
    it.each`
      inputTags       | isMobile | isVisible
      ${tags}         | ${false} | ${true}
      ${tags}         | ${true}  | ${false}
      ${readOnlyTags} | ${false} | ${false}
      ${readOnlyTags} | ${true}  | ${false}
    `(
      'is $isVisible that delete button exists when tags is $inputTags and isMobile is $isMobile',
      async ({ inputTags, isMobile, isVisible }) => {
        mountComponent({
          propsData: { tags: inputTags, isMobile, id: 1 },
          resolver: jest.fn().mockResolvedValue(imageTagsMock(inputTags)),
        });

        await waitForApolloRequestRender();

        expect(findDeleteButton().exists()).toBe(isVisible);
      },
    );

    it('has the correct text', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findDeleteButton().text()).toBe(REMOVE_TAGS_BUTTON_TITLE);
    });

    it('has the correct props', async () => {
      mountComponent();
      await waitForApolloRequestRender();

      expect(findDeleteButton().attributes()).toMatchObject({
        category: 'secondary',
        variant: 'danger',
      });
    });

    it.each`
      disabled | doSelect | buttonDisabled
      ${true}  | ${false} | ${'true'}
      ${true}  | ${true}  | ${'true'}
      ${false} | ${false} | ${'true'}
      ${false} | ${true}  | ${undefined}
    `(
      'is $buttonDisabled that the button is disabled when the component disabled state is $disabled and is $doSelect that the user selected a tag',
      async ({ disabled, buttonDisabled, doSelect }) => {
        mountComponent({ propsData: { tags, disabled, isMobile: false, id: 1 } });

        await waitForApolloRequestRender();

        if (doSelect) {
          findTagsListRow().at(0).vm.$emit('select');
          await nextTick();
        }

        expect(findDeleteButton().attributes('disabled')).toBe(buttonDisabled);
      },
    );

    it('click event emits a deleted event with selected items', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      findTagsListRow().at(0).vm.$emit('select');
      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')[0][0][0].name).toBe(tags[0].name);
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
    const resolver = jest.fn().mockResolvedValue(imageTagsMock([]));

    it('has the empty state', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show the loader', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findTagsLoader().exists()).toBe(false);
    });

    it('does not show the list', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findTagsListRow().exists()).toBe(false);
      expect(findListTitle().exists()).toBe(false);
    });
  });

  describe('pagination', () => {
    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findPagination().exists()).toBe(true);
    });

    it('is hidden when loading', () => {
      mountComponent();

      expect(findPagination().exists()).toBe(false);
    });

    it('is hidden when there are no more pages', async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(imageTagsMock([])) });

      await waitForApolloRequestRender();

      expect(findPagination().exists()).toBe(false);
    });

    it('is wired to the correct pagination props', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findPagination().props()).toMatchObject({
        hasNextPage: tagsPageInfo.hasNextPage,
        hasPreviousPage: tagsPageInfo.hasPreviousPage,
      });
    });

    it('fetch next page when user clicks next', async () => {
      const resolver = jest.fn().mockResolvedValue(imageTagsMock());
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      findPagination().vm.$emit('next');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ after: tagsPageInfo.endCursor }),
      );
    });

    it('fetch previous page when user clicks prev', async () => {
      const resolver = jest.fn().mockResolvedValue(imageTagsMock());
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      findPagination().vm.$emit('prev');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ first: null, before: tagsPageInfo.startCursor }),
      );
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
        expect(findListTitle().exists()).toBe(!loadingVisible);
        expect(findPagination().exists()).toBe(!loadingVisible);
      },
    );
  });
});
