import { GlKeysetPagination, GlEmptyState, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { helpPagePath } from '~/helpers/help_page_helper';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import DeleteImage from '~/packages_and_registries/container_registry/explorer/components/delete_image.vue';
import DeleteAlert from '~/packages_and_registries/container_registry/explorer/components/details_page/delete_alert.vue';
import DetailsHeader from '~/packages_and_registries/container_registry/explorer/components/details_page/details_header.vue';
import PartialCleanupAlert from '~/packages_and_registries/container_registry/explorer/components/details_page/partial_cleanup_alert.vue';
import StatusAlert from '~/packages_and_registries/container_registry/explorer/components/details_page/status_alert.vue';
import TagsList from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list.vue';

import {
  UNFINISHED_STATUS,
  DELETE_SCHEDULED,
  ALERT_DANGER_IMAGE,
  MISSING_OR_DELETED_IMAGE_BREADCRUMB,
  MISSING_OR_DELETED_IMAGE_TITLE,
  MISSING_OR_DELETED_IMAGE_MESSAGE,
} from '~/packages_and_registries/container_registry/explorer/constants';
import getContainerRepositoryDetailsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_details.query.graphql';

import component from '~/packages_and_registries/container_registry/explorer/pages/details.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

import {
  graphQLImageDetailsMock,
  containerRepositoryMock,
  graphQLEmptyImageDetailsMock,
} from '../mock_data';
import { DeleteModal } from '../stubs';

describe('Details Page', () => {
  let wrapper;
  let apolloProvider;

  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTagsList = () => wrapper.findComponent(TagsList);
  const findDeleteAlert = () => wrapper.findComponent(DeleteAlert);
  const findDetailsHeader = () => wrapper.findComponent(DetailsHeader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPartialCleanupAlert = () => wrapper.findComponent(PartialCleanupAlert);
  const findStatusAlert = () => wrapper.findComponent(StatusAlert);
  const findDeleteImage = () => wrapper.findComponent(DeleteImage);

  const routeId = 1;

  const breadCrumbState = {
    updateName: jest.fn(),
  };

  const defaultConfig = {
    noContainersImage: 'noContainersImage',
    projectListUrl: 'projectListUrl',
    groupListUrl: 'groupListUrl',
    isGroupPage: false,
  };

  const waitForApolloRequestRender = async () => {
    await waitForPromises();
    await nextTick();
  };

  const mountComponent = ({
    resolver = jest.fn().mockResolvedValue(graphQLImageDetailsMock()),
    options,
    config = defaultConfig,
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[getContainerRepositoryDetailsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
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

  describe('when isLoading is true', () => {
    it('shows the loader', () => {
      mountComponent();

      expect(findLoader().exists()).toBe(true);
    });

    it('sets loading prop on tags list component', () => {
      mountComponent();

      expect(findTagsList().props('isImageLoading')).toBe(true);
    });
  });

  describe('when the image does not exist', () => {
    it('does not show the default ui', async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(graphQLEmptyImageDetailsMock) });

      await waitForApolloRequestRender();

      expect(findLoader().exists()).toBe(false);
      expect(findDetailsHeader().exists()).toBe(false);
      expect(findTagsList().exists()).toBe(false);
      expect(findPagination().exists()).toBe(false);
    });

    it('shows an empty state message', async () => {
      mountComponent({ resolver: jest.fn().mockResolvedValue(graphQLEmptyImageDetailsMock) });

      await waitForApolloRequestRender();

      expect(findEmptyState().props()).toMatchObject({
        description: MISSING_OR_DELETED_IMAGE_MESSAGE,
        svgPath: defaultConfig.noContainersImage,
        title: MISSING_OR_DELETED_IMAGE_TITLE,
      });
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
  });

  describe('modal', () => {
    it('exists', async () => {
      mountComponent();

      await waitForApolloRequestRender();

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
        mountComponent();

        await waitForApolloRequestRender();

        findDeleteModal().vm.$emit('cancel');

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'cancel_delete', {
          label: 'registry_image_delete',
        });
      });
    });

    describe('tags list delete event', () => {
      beforeEach(() => {
        mountComponent();

        return waitForApolloRequestRender();
      });

      it('sets delete alert modal deleteAlertType value', async () => {
        findTagsList().vm.$emit('delete', 'success_tag');

        await nextTick();

        expect(findDeleteAlert().props('deleteAlertType')).toBe('success_tag');
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

      expect(findDeleteAlert().props()).toEqual({
        ...config,
        deleteAlertType,
        garbageCollectionHelpPagePath: helpPagePath('administration/packages/container_registry', {
          anchor: 'container-registry-garbage-collection',
        }),
      });
    });
  });

  describe('Partial Cleanup Alert', () => {
    const config = {
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
          cleanupPoliciesHelpPagePath: helpPagePath(
            'user/packages/container_registry/reduce_container_registry_storage',
            {
              anchor: 'cleanup-policy',
            },
          ),
          runCleanupPoliciesHelpPagePath: helpPagePath(
            'administration/packages/container_registry',
            {
              anchor: 'run-the-cleanup-policy',
            },
          ),
        });
      });

      it('dismiss hides the component', async () => {
        jest.spyOn(axios, 'post').mockReturnValue();

        mountComponent({ resolver, config });

        await waitForApolloRequestRender();

        expect(findPartialCleanupAlert().exists()).toBe(true);

        findPartialCleanupAlert().vm.$emit('dismiss');

        await nextTick();

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

    it(`when the image has no name set the breadcrumb to project name`, async () => {
      mountComponent({
        resolver: jest
          .fn()
          .mockResolvedValue(graphQLImageDetailsMock({ ...containerRepositoryMock, name: null })),
      });

      await waitForApolloRequestRender();

      expect(breadCrumbState.updateName).toHaveBeenCalledWith('gitlab-test');
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

      await nextTick();
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

      await waitForPromises();

      expect(findLoader().exists()).toBe(true);
      expect(findTagsList().props('isImageLoading')).toBe(true);

      findDeleteImage().vm.$emit('end');

      await nextTick();

      expect(findLoader().exists()).toBe(false);
      expect(findTagsList().props('isImageLoading')).toBe(false);
    });

    it('binds correctly to delete-image error event', async () => {
      mountComponent();

      findDeleteImage().vm.$emit('error');

      await nextTick();

      expect(findDeleteAlert().props('deleteAlertType')).toBe(ALERT_DANGER_IMAGE);
    });
  });
});
