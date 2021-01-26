import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlKeysetPagination } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Tracking from '~/tracking';
import axios from '~/lib/utils/axios_utils';
import component from '~/registry/explorer/pages/details.vue';
import DeleteAlert from '~/registry/explorer/components/details_page/delete_alert.vue';
import PartialCleanupAlert from '~/registry/explorer/components/details_page/partial_cleanup_alert.vue';
import DetailsHeader from '~/registry/explorer/components/details_page/details_header.vue';
import TagsLoader from '~/registry/explorer/components/details_page/tags_loader.vue';
import TagsList from '~/registry/explorer/components/details_page/tags_list.vue';
import EmptyTagsState from '~/registry/explorer/components/details_page/empty_tags_state.vue';

import getContainerRepositoryDetailsQuery from '~/registry/explorer/graphql/queries/get_container_repository_details.query.graphql';
import deleteContainerRepositoryTagsMutation from '~/registry/explorer/graphql/mutations/delete_container_repository_tags.mutation.graphql';

import { UNFINISHED_STATUS } from '~/registry/explorer/constants/index';

import {
  graphQLImageDetailsMock,
  graphQLImageDetailsEmptyTagsMock,
  graphQLDeleteImageRepositoryTagsMock,
  containerRepositoryMock,
  tagsMock,
  tagsPageInfo,
} from '../mock_data';
import { DeleteModal } from '../stubs';

const localVue = createLocalVue();

describe('Details Page', () => {
  let wrapper;
  let apolloProvider;

  const findDeleteModal = () => wrapper.find(DeleteModal);
  const findPagination = () => wrapper.find(GlKeysetPagination);
  const findTagsLoader = () => wrapper.find(TagsLoader);
  const findTagsList = () => wrapper.find(TagsList);
  const findDeleteAlert = () => wrapper.find(DeleteAlert);
  const findDetailsHeader = () => wrapper.find(DetailsHeader);
  const findEmptyTagsState = () => wrapper.find(EmptyTagsState);
  const findPartialCleanupAlert = () => wrapper.find(PartialCleanupAlert);

  const routeId = 1;

  const breadCrumbState = {
    updateName: jest.fn(),
  };

  const cleanTags = tagsMock.map((t) => {
    const result = { ...t };
    // eslint-disable-next-line no-underscore-dangle
    delete result.__typename;
    return result;
  });

  const waitForApolloRequestRender = async () => {
    await waitForPromises();
    await wrapper.vm.$nextTick();
  };

  const tagsArrayToSelectedTags = (tags) =>
    tags.reduce((acc, c) => {
      acc[c.name] = true;
      return acc;
    }, {});

  const mountComponent = ({
    resolver = jest.fn().mockResolvedValue(graphQLImageDetailsMock()),
    mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock),
    options,
    config = {},
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getContainerRepositoryDetailsQuery, resolver],
      [deleteContainerRepositoryTagsMutation, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      stubs: {
        DeleteModal,
      },
      mocks: {
        $route: {
          params: {
            id: routeId,
          },
        },
      },
      provide() {
        return {
          breadCrumbState,
          config,
        };
      },
      ...options,
    });
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when isLoading is true', () => {
    it('shows the loader', () => {
      mountComponent();

      expect(findTagsLoader().exists()).toBe(true);
    });

    it('does not show the list', () => {
      mountComponent();

      expect(findTagsList().exists()).toBe(false);
    });

    it('does not show pagination', () => {
      mountComponent();

      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('when the list of tags is empty', () => {
    const resolver = jest.fn().mockResolvedValue(graphQLImageDetailsEmptyTagsMock);

    it('has the empty state', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findEmptyTagsState().exists()).toBe(true);
    });

    it('does not show the loader', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findTagsLoader().exists()).toBe(false);
    });

    it('does not show the list', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findTagsList().exists()).toBe(false);
    });
  });

  describe('list', () => {
    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findTagsList().exists()).toBe(true);
    });

    it('has the correct props bound', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findTagsList().props()).toMatchObject({
        isMobile: false,
        tags: cleanTags,
      });
    });

    describe('deleteEvent', () => {
      describe('single item', () => {
        let tagToBeDeleted;
        beforeEach(async () => {
          mountComponent();

          await waitForApolloRequestRender();

          [tagToBeDeleted] = cleanTags;
          findTagsList().vm.$emit('delete', { [tagToBeDeleted.name]: true });
        });

        it('open the modal', async () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('tracks a single delete event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });
      });

      describe('multiple items', () => {
        beforeEach(async () => {
          mountComponent();

          await waitForApolloRequestRender();

          findTagsList().vm.$emit('delete', tagsArrayToSelectedTags(cleanTags));
        });

        it('open the modal', () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('tracks a single delete event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'bulk_registry_tag_delete',
          });
        });
      });
    });
  });

  describe('pagination', () => {
    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(findPagination().exists()).toBe(true);
    });

    it('is hidden when there are no more pages', async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(graphQLImageDetailsEmptyTagsMock) });

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
      const resolver = jest.fn().mockResolvedValue(graphQLImageDetailsMock());
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      findPagination().vm.$emit('next');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ after: tagsPageInfo.endCursor }),
      );
    });

    it('fetch previous page when user clicks prev', async () => {
      const resolver = jest.fn().mockResolvedValue(graphQLImageDetailsMock());
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      findPagination().vm.$emit('prev');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ first: null, before: tagsPageInfo.startCursor }),
      );
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

      beforeEach(() => {
        mutationResolver = jest.fn().mockResolvedValue(graphQLDeleteImageRepositoryTagsMock);
        mountComponent({ mutationResolver });

        return waitForApolloRequestRender();
      });
      describe('when one item is selected to be deleted', () => {
        it('calls apollo mutation with the right parameters', async () => {
          findTagsList().vm.$emit('delete', { [cleanTags[0].name]: true });

          await wrapper.vm.$nextTick();

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [cleanTags[0].name] }),
          );
        });
      });

      describe('when more than one item is selected to be deleted', () => {
        it('calls apollo mutation with the right parameters', async () => {
          findTagsList().vm.$emit('delete', { ...tagsArrayToSelectedTags(tagsMock) });

          await wrapper.vm.$nextTick();

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: tagsMock.map((t) => t.name) }),
          );
        });
      });
    });
  });

  describe('Header', () => {
    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();
      expect(findDetailsHeader().exists()).toBe(true);
    });

    it('has the correct props', async () => {
      mountComponent();

      await waitForApolloRequestRender();
      expect(findDetailsHeader().props()).toMatchObject({
        metadataLoading: false,
        image: {
          name: containerRepositoryMock.name,
          project: {
            visibility: containerRepositoryMock.project.visibility,
          },
        },
      });
    });
  });

  describe('Delete Alert', () => {
    const config = {
      isAdmin: true,
      garbageCollectionHelpPagePath: 'baz',
    };
    const deleteAlertType = 'success_tag';

    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();
      expect(findDeleteAlert().exists()).toBe(true);
    });

    it('has the correct props', async () => {
      mountComponent({
        options: {
          data: () => ({
            deleteAlertType,
          }),
        },
        config,
      });

      await waitForApolloRequestRender();

      expect(findDeleteAlert().props()).toEqual({ ...config, deleteAlertType });
    });
  });

  describe('Partial Cleanup Alert', () => {
    const config = {
      runCleanupPoliciesHelpPagePath: 'foo',
      cleanupPoliciesHelpPagePath: 'bar',
      userCalloutsPath: 'call_out_path',
      userCalloutId: 'call_out_id',
      showUnfinishedTagCleanupCallout: true,
    };

    describe(`when expirationPolicyCleanupStatus is ${UNFINISHED_STATUS}`, () => {
      let resolver;

      beforeEach(() => {
        resolver = jest.fn().mockResolvedValue(
          graphQLImageDetailsMock({
            expirationPolicyCleanupStatus: UNFINISHED_STATUS,
          }),
        );
      });

      it('exists', async () => {
        mountComponent({ resolver, config });

        await waitForApolloRequestRender();

        expect(findPartialCleanupAlert().exists()).toBe(true);
      });

      it('has the correct props', async () => {
        mountComponent({ resolver, config });

        await waitForApolloRequestRender();

        expect(findPartialCleanupAlert().props()).toEqual({
          runCleanupPoliciesHelpPagePath: config.runCleanupPoliciesHelpPagePath,
          cleanupPoliciesHelpPagePath: config.cleanupPoliciesHelpPagePath,
        });
      });

      it('dismiss hides the component', async () => {
        jest.spyOn(axios, 'post').mockReturnValue();

        mountComponent({ resolver, config });

        await waitForApolloRequestRender();

        expect(findPartialCleanupAlert().exists()).toBe(true);

        findPartialCleanupAlert().vm.$emit('dismiss');

        await wrapper.vm.$nextTick();

        expect(axios.post).toHaveBeenCalledWith(config.userCalloutsPath, {
          feature_name: config.userCalloutId,
        });
        expect(findPartialCleanupAlert().exists()).toBe(false);
      });

      it('is hidden if the callout is dismissed', async () => {
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        expect(findPartialCleanupAlert().exists()).toBe(false);
      });
    });

    describe(`when expirationPolicyCleanupStatus is not ${UNFINISHED_STATUS}`, () => {
      it('the component is hidden', async () => {
        mountComponent({ config });

        await waitForApolloRequestRender();

        expect(findPartialCleanupAlert().exists()).toBe(false);
      });
    });
  });

  describe('Breadcrumb connection', () => {
    it('when the details are fetched updates the name', async () => {
      mountComponent();

      await waitForApolloRequestRender();

      expect(breadCrumbState.updateName).toHaveBeenCalledWith(containerRepositoryMock.name);
    });
  });
});
