import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import DeleteImage from '~/registry/explorer/components/delete_image.vue';
import DeleteAlert from '~/registry/explorer/components/details_page/delete_alert.vue';
import DetailsHeader from '~/registry/explorer/components/details_page/details_header.vue';
import EmptyTagsState from '~/registry/explorer/components/details_page/empty_state.vue';
import PartialCleanupAlert from '~/registry/explorer/components/details_page/partial_cleanup_alert.vue';
import StatusAlert from '~/registry/explorer/components/details_page/status_alert.vue';
import TagsList from '~/registry/explorer/components/details_page/tags_list.vue';
import TagsLoader from '~/registry/explorer/components/details_page/tags_loader.vue';

import {
  UNFINISHED_STATUS,
  DELETE_SCHEDULED,
  ALERT_DANGER_IMAGE,
  MISSING_OR_DELETED_IMAGE_BREADCRUMB,
  ROOT_IMAGE_TEXT,
} from '~/registry/explorer/constants';
import deleteContainerRepositoryTagsMutation from '~/registry/explorer/graphql/mutations/delete_container_repository_tags.mutation.graphql';
import getContainerRepositoryDetailsQuery from '~/registry/explorer/graphql/queries/get_container_repository_details.query.graphql';

import component from '~/registry/explorer/pages/details.vue';
import Tracking from '~/tracking';

import {
  graphQLImageDetailsMock,
  graphQLDeleteImageRepositoryTagsMock,
  containerRepositoryMock,
  graphQLEmptyImageDetailsMock,
  tagsMock,
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
  const findEmptyState = () => wrapper.find(EmptyTagsState);
  const findPartialCleanupAlert = () => wrapper.find(PartialCleanupAlert);
  const findStatusAlert = () => wrapper.find(StatusAlert);
  const findDeleteImage = () => wrapper.find(DeleteImage);

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
        DeleteImage,
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
  });

  describe('when the image does not exist', () => {
    it('does not show the default ui', async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(graphQLEmptyImageDetailsMock) });

      await waitForApolloRequestRender();

      expect(findTagsLoader().exists()).toBe(false);
      expect(findDetailsHeader().exists()).toBe(false);
      expect(findTagsList().exists()).toBe(false);
      expect(findPagination().exists()).toBe(false);
    });

    it('shows an empty state message', async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(graphQLEmptyImageDetailsMock) });

      await waitForApolloRequestRender();

      expect(findEmptyState().exists()).toBe(true);
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
      });
    });

    describe('deleteEvent', () => {
      describe('single item', () => {
        let tagToBeDeleted;
        beforeEach(async () => {
          mountComponent();

          await waitForApolloRequestRender();

          [tagToBeDeleted] = cleanTags;
          findTagsList().vm.$emit('delete', [tagToBeDeleted]);
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

          findTagsList().vm.$emit('delete', cleanTags);
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
          findTagsList().vm.$emit('delete', [cleanTags[0]]);

          await wrapper.vm.$nextTick();

          findDeleteModal().vm.$emit('confirmDelete');

          expect(mutationResolver).toHaveBeenCalledWith(
            expect.objectContaining({ tagNames: [cleanTags[0].name] }),
          );
        });
      });

      describe('when more than one item is selected to be deleted', () => {
        it('calls apollo mutation with the right parameters', async () => {
          findTagsList().vm.$emit('delete', tagsMock);

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

    it(`when the image is missing set the breadcrumb to ${MISSING_OR_DELETED_IMAGE_BREADCRUMB}`, async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(graphQLEmptyImageDetailsMock) });

      await waitForApolloRequestRender();

      expect(breadCrumbState.updateName).toHaveBeenCalledWith(MISSING_OR_DELETED_IMAGE_BREADCRUMB);
    });

    it(`when the image has no name set the breadcrumb to ${ROOT_IMAGE_TEXT}`, async () => {
      mountComponent({
        resolver: jest
          .fn()
          .mockResolvedValue(graphQLImageDetailsMock({ ...containerRepositoryMock, name: null })),
      });

      await waitForApolloRequestRender();

      expect(breadCrumbState.updateName).toHaveBeenCalledWith(ROOT_IMAGE_TEXT);
    });
  });

  describe('when the image has a status different from null', () => {
    const resolver = jest
      .fn()
      .mockResolvedValue(graphQLImageDetailsMock({ status: DELETE_SCHEDULED }));
    it('disables all the actions', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findDetailsHeader().props('disabled')).toBe(true);
      expect(findTagsList().props('disabled')).toBe(true);
    });

    it('shows a status alert', async () => {
      mountComponent({ resolver });

      await waitForApolloRequestRender();

      expect(findStatusAlert().exists()).toBe(true);
      expect(findStatusAlert().props()).toMatchObject({
        status: DELETE_SCHEDULED,
      });
    });
  });

  describe('delete the image', () => {
    const mountComponentAndDeleteImage = async () => {
      mountComponent();

      await waitForApolloRequestRender();
      findDetailsHeader().vm.$emit('delete');

      await wrapper.vm.$nextTick();
    };

    it('on delete event it deletes the image', async () => {
      await mountComponentAndDeleteImage();

      findDeleteModal().vm.$emit('confirmDelete');

      expect(findDeleteImage().emitted('start')).toEqual([[]]);
    });

    it('binds the correct props to the modal', async () => {
      await mountComponentAndDeleteImage();

      expect(findDeleteModal().props()).toMatchObject({
        itemsToBeDeleted: [{ path: 'gitlab-org/gitlab-test/rails-12009' }],
        deleteImage: true,
      });
    });

    it('binds correctly to delete-image start and end events', async () => {
      mountComponent();

      findDeleteImage().vm.$emit('start');

      await wrapper.vm.$nextTick();

      expect(findTagsLoader().exists()).toBe(true);

      findDeleteImage().vm.$emit('end');

      await wrapper.vm.$nextTick();

      expect(findTagsLoader().exists()).toBe(false);
    });

    it('binds correctly to delete-image error event', async () => {
      mountComponent();

      findDeleteImage().vm.$emit('error');

      await wrapper.vm.$nextTick();

      expect(findDeleteAlert().props('deleteAlertType')).toBe(ALERT_DANGER_IMAGE);
    });
  });
});
