import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import PackageVersionsList from '~/packages_and_registries/package_registry/components/details/package_versions_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import {
  CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  GRAPHQL_PAGE_SIZE,
} from '~/packages_and_registries/package_registry/constants';
import getPackageVersionsQuery from '~/packages_and_registries/package_registry/graphql//queries/get_package_versions.query.graphql';
import {
  emptyPackageVersionsQuery,
  packageVersionsQuery,
  packageVersions,
  pagination,
} from '../../mock_data';

Vue.use(VueApollo);

describe('PackageVersionsList', () => {
  let wrapper;
  let apolloProvider;

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>empty message</div>' };

  const uiElements = {
    findAlert: () => wrapper.findComponent(GlAlert),
    findLoader: () => wrapper.findComponent(PackagesListLoader),
    findRegistryList: () => wrapper.findComponent(RegistryList),
    findEmptySlot: () => wrapper.findComponent(EmptySlotStub),
    findListRow: () => wrapper.findComponent(VersionRow),
    findAllListRow: () => wrapper.findAllComponents(VersionRow),
    findDeletePackagesModal: () => wrapper.findComponent(DeleteModal),
  };

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(packageVersionsQuery()),
  } = {}) => {
    const requestHandlers = [[getPackageVersionsQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackageVersionsList, {
      apolloProvider,
      propsData: {
        packageId: packageVersionsQuery().data.package.id,
        isMutationLoading: false,
        count: packageVersions().length,
        ...props,
      },
      stubs: {
        RegistryList,
        DeleteModal: stubComponent(DeleteModal, {
          methods: {
            show: jest.fn(),
          },
        }),
      },
      slots: {
        'empty-state': EmptySlotStub,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  describe('when list is loading', () => {
    beforeEach(() => {
      mountComponent({ props: { isMutationLoading: true } });
    });
    it('displays loader', () => {
      expect(uiElements.findLoader().exists()).toBe(true);
    });

    it('does not display rows', () => {
      expect(uiElements.findListRow().exists()).toBe(false);
    });

    it('does not display empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(uiElements.findRegistryList().exists()).toBe(false);
    });

    it('does not display alert', () => {
      expect(uiElements.findAlert().exists()).toBe(false);
    });
  });

  describe('when list is loaded and has no data', () => {
    const resolver = jest.fn().mockResolvedValue(emptyPackageVersionsQuery);
    beforeEach(async () => {
      mountComponent({
        props: { isMutationLoading: false, count: 0 },
        resolver,
      });
      await waitForPromises();
    });

    it('skips graphql query', () => {
      expect(resolver).not.toHaveBeenCalled();
    });

    it('displays empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(true);
    });

    it('does not display loader', () => {
      expect(uiElements.findLoader().exists()).toBe(false);
    });

    it('does not display rows', () => {
      expect(uiElements.findListRow().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(uiElements.findRegistryList().exists()).toBe(false);
    });

    it('does not display alert', () => {
      expect(uiElements.findAlert().exists()).toBe(false);
    });
  });

  describe('if load fails, alert', () => {
    beforeEach(async () => {
      mountComponent({ resolver: jest.fn().mockRejectedValue() });

      await waitForPromises();
    });

    it('is displayed', () => {
      expect(uiElements.findAlert().exists()).toBe(true);
    });

    it('shows error message', () => {
      expect(uiElements.findAlert().text()).toMatchInterpolatedText('Failed to load version data');
    });

    it('is not dismissible', () => {
      expect(uiElements.findAlert().props('dismissible')).toBe(false);
    });

    it('is of variant danger', () => {
      expect(uiElements.findAlert().attributes('variant')).toBe('danger');
    });

    it('error is logged in sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('displays package registry list', () => {
      expect(uiElements.findRegistryList().exists()).toEqual(true);
    });

    it('binds the right props', () => {
      expect(uiElements.findRegistryList().props()).toMatchObject({
        items: packageVersions(),
        pagination: {},
        isLoading: false,
        hiddenDelete: true,
      });
    });

    it('displays package version rows', () => {
      expect(uiElements.findAllListRow().exists()).toEqual(true);
      expect(uiElements.findAllListRow()).toHaveLength(packageVersions().length);
    });

    it('binds the correct props', () => {
      expect(uiElements.findAllListRow().at(0).props()).toMatchObject({
        packageEntity: expect.objectContaining(packageVersions()[0]),
      });

      expect(uiElements.findAllListRow().at(1).props()).toMatchObject({
        packageEntity: expect.objectContaining(packageVersions()[1]),
      });
    });

    it('does not display loader', () => {
      expect(uiElements.findLoader().exists()).toBe(false);
    });

    it('does not display empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    const resolver = jest.fn().mockResolvedValue(packageVersionsQuery());

    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('when list emits next-page fetches the next set of records', async () => {
      uiElements.findRegistryList().vm.$emit('next-page');
      await waitForPromises();

      expect(resolver).toHaveBeenLastCalledWith(
        expect.objectContaining({ after: pagination().endCursor, first: GRAPHQL_PAGE_SIZE }),
      );
    });

    it('when list emits prev-page fetches the prev set of records', async () => {
      uiElements.findRegistryList().vm.$emit('prev-page');
      await waitForPromises();

      expect(resolver).toHaveBeenLastCalledWith(
        expect.objectContaining({ before: pagination().startCursor, last: GRAPHQL_PAGE_SIZE }),
      );
    });
  });

  describe.each`
    description                                                               | finderFunction                 | deletePayload
    ${'when the user can destroy the package'}                                | ${uiElements.findListRow}      | ${packageVersions()[0]}
    ${'when the user can bulk destroy packages and deletes only one package'} | ${uiElements.findRegistryList} | ${[packageVersions()[0]]}
  `('$description', ({ finderFunction, deletePayload }) => {
    let eventSpy;
    const category = 'UI::NpmPackages';
    const { findDeletePackagesModal } = uiElements;

    beforeEach(async () => {
      eventSpy = mockTracking(undefined, undefined, jest.spyOn);
      mountComponent({ props: { canDestroy: true } });
      await waitForPromises();
      finderFunction().vm.$emit('delete', deletePayload);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('passes itemsToBeDeleted to the modal', () => {
      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual([
        packageVersions()[0],
      ]);
    });

    it('requesting delete tracks the right action', () => {
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
        expect.any(Object),
      );
    });

    describe('when modal confirms', () => {
      beforeEach(() => {
        findDeletePackagesModal().vm.$emit('confirm');
      });

      it('emits delete when modal confirms', () => {
        expect(wrapper.emitted('delete')[0][0]).toEqual([packageVersions()[0]]);
      });

      it('tracks the right action', () => {
        expect(eventSpy).toHaveBeenCalledWith(
          category,
          DELETE_PACKAGE_VERSION_TRACKING_ACTION,
          expect.any(Object),
        );
      });
    });

    it.each(['confirm', 'cancel'])('resets itemsToBeDeleted when modal emits %s', async (event) => {
      await findDeletePackagesModal().vm.$emit(event);

      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toEqual([]);
    });

    it('canceling delete tracks the right action', () => {
      findDeletePackagesModal().vm.$emit('cancel');

      expect(eventSpy).toHaveBeenCalledWith(
        category,
        CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
        expect.any(Object),
      );
    });
  });

  describe('when the user can bulk destroy versions', () => {
    let eventSpy;
    const { findDeletePackagesModal, findRegistryList } = uiElements;

    beforeEach(async () => {
      eventSpy = mockTracking(undefined, undefined, jest.spyOn);
      mountComponent({ props: { canDestroy: true } });
      await waitForPromises();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('binds the right props', () => {
      expect(uiElements.findRegistryList().props()).toMatchObject({
        items: packageVersions(),
        pagination: {},
        isLoading: false,
        hiddenDelete: false,
        title: '2 versions',
      });
    });

    describe('upon deletion', () => {
      beforeEach(() => {
        findRegistryList().vm.$emit('delete', packageVersions());
      });

      it('passes itemsToBeDeleted to the modal', () => {
        expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual(
          packageVersions(),
        );
        expect(wrapper.emitted('delete')).toBeUndefined();
      });

      it('requesting delete tracks the right action', () => {
        expect(eventSpy).toHaveBeenCalledWith(
          undefined,
          REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
          expect.any(Object),
        );
      });

      describe('when modal confirms', () => {
        beforeEach(() => {
          findDeletePackagesModal().vm.$emit('confirm');
        });

        it('emits delete event', () => {
          expect(wrapper.emitted('delete')[0]).toEqual([packageVersions()]);
        });

        it('tracks the right action', () => {
          expect(eventSpy).toHaveBeenCalledWith(
            undefined,
            DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
            expect.any(Object),
          );
        });
      });

      it.each(['confirm', 'cancel'])(
        'resets itemsToBeDeleted when modal emits %s',
        async (event) => {
          await findDeletePackagesModal().vm.$emit(event);

          expect(findDeletePackagesModal().props('itemsToBeDeleted')).toHaveLength(0);
        },
      );

      it('canceling delete tracks the right action', () => {
        findDeletePackagesModal().vm.$emit('cancel');

        expect(eventSpy).toHaveBeenCalledWith(
          undefined,
          CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
          expect.any(Object),
        );
      });
    });
  });

  describe('with isRequestForwardingEnabled prop', () => {
    const { findDeletePackagesModal } = uiElements;

    it.each([true, false])('sets modal prop showRequestForwardingContent to %s', async (value) => {
      mountComponent({ props: { isRequestForwardingEnabled: value } });
      await waitForPromises();

      expect(findDeletePackagesModal().props('showRequestForwardingContent')).toBe(value);
    });
  });
});
