import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import PackageErrorsCount from '~/packages_and_registries/package_registry/components/list/package_errors_count.vue';
import getPackageErrorsCountQuery from '~/packages_and_registries/package_registry/graphql/queries/get_package_errors_count.query.graphql';
import { errorPackagesListQuery } from '../../mock_data';

Vue.use(VueApollo);

describe('PackageErrorsCount', () => {
  let apolloProvider;
  let wrapper;

  const mockFullPath = 'test-group/test-project';

  const firstPackage = {
    __typename: 'Package',
    id: 'gid://gitlab/Packages::Package/1',
    name: '@gitlab-org/package-15',
    statusMessage: 'custom error message',
    version: '1.0.0',
  };

  const secondPackage = {
    __typename: 'Package',
    id: 'gid://gitlab/Packages::Package/2',
    name: '@gitlab-org/package-16',
    statusMessage: null,
    version: '2.0.0',
  };

  const defaultProvide = {
    isGroupPage: true,
    fullPath: mockFullPath,
  };

  const findDeletePackagesModal = () => wrapper.findComponent(DeleteModal);
  const findErrorPackageAlert = () => wrapper.findComponent(GlAlert);
  const findErrorAlertButton = () => findErrorPackageAlert().findComponent(GlButton);

  const showMock = jest.fn();

  const mountComponent = ({
    provide = {},
    resolver = jest
      .fn()
      .mockResolvedValue(errorPackagesListQuery({ extend: { count: 1, nodes: [firstPackage] } })),
    stubs = {},
  } = {}) => {
    const requestHandlers = [[getPackageErrorsCountQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackageErrorsCount, {
      apolloProvider,
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        DeleteModal: stubComponent(DeleteModal, {
          methods: {
            show: showMock,
          },
        }),
        ...stubs,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  describe.each`
    description                       | resolver                                                                                    | isError
    ${'empty response'}               | ${jest.fn().mockResolvedValue(errorPackagesListQuery({ extend: { nodes: [], count: 0 } }))} | ${false}
    ${'error response'}               | ${jest.fn().mockResolvedValue({ data: { group: null } })}                                   | ${true}
    ${'unhandled exception response'} | ${jest.fn().mockRejectedValue(new Error('error'))}                                          | ${true}
  `(`with $description`, ({ resolver, isError }) => {
    beforeEach(async () => {
      mountComponent({ resolver });

      await waitForPromises();
    });

    it('does not show alert', () => {
      expect(findErrorPackageAlert().exists()).toBe(false);
    });

    if (isError) {
      it('captures error in Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalled();
      });
    }
  });

  describe.each`
    type
    ${WORKSPACE_PROJECT}
    ${WORKSPACE_GROUP}
  `('$type query', ({ type }) => {
    let provide;
    let resolver;

    const isGroupPage = type === WORKSPACE_GROUP;

    beforeEach(async () => {
      provide = { ...defaultProvide, isGroupPage };
      resolver = jest
        .fn()
        .mockResolvedValue(errorPackagesListQuery({ type, extend: { nodes: [], count: 0 } }));

      mountComponent({
        provide,
        resolver,
      });
      await waitForPromises();
    });

    it('calls the resolver with the right parameters', () => {
      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ isGroupPage, fullPath: defaultProvide.fullPath }),
      );
    });

    it('expects not to call sentry', () => {
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });
  });

  describe('when an error package is present', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('should display an alert with the package name in the title', () => {
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing @gitlab-org/package-15',
      );
    });

    describe('when statusMessage is returned', () => {
      it('should display the statusMessage in the alert body', () => {
        expect(findErrorPackageAlert().text()).toBe(
          'custom error message. Delete this package and try again.',
        );
      });
    });

    describe('when no statusMessage is returned', () => {
      beforeEach(async () => {
        const withoutStatusMessage = errorPackagesListQuery({
          extend: {
            count: 1,
            nodes: [secondPackage],
          },
        });
        mountComponent({
          resolver: jest.fn().mockResolvedValue(withoutStatusMessage),
        });
        await waitForPromises();
      });

      it('should display the generic package error in the alert body', () => {
        expect(findErrorPackageAlert().text()).toBe(
          'Invalid Package: failed metadata extraction. Delete this package and try again.',
        );
      });
    });

    describe('`Delete this package` button', () => {
      beforeEach(async () => {
        mountComponent({
          stubs: { GlAlert },
        });
        await waitForPromises();
      });

      it('displays the button within the alert', () => {
        expect(findErrorAlertButton().text()).toBe('Delete this package');
      });

      it('has tracking attributes', () => {
        expect(findErrorAlertButton().attributes()).toMatchObject({
          'data-event-tracking': 'click_delete_package_button',
          'data-event-label': 'package_errors_alert',
        });
      });

      it('should display the deletion modal when clicked on the `Delete this package` button', async () => {
        findErrorAlertButton().vm.$emit('click');

        await nextTick();

        expect(showMock).toHaveBeenCalledTimes(1);

        expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual([firstPackage]);
      });

      describe('when modal confirms', () => {
        beforeEach(() => {
          findErrorAlertButton().vm.$emit('click');
          findDeletePackagesModal().vm.$emit('confirm');
        });

        it('emits delete when modal confirms', () => {
          expect(wrapper.emitted('confirm-delete')[0][0]).toEqual([firstPackage]);
        });
      });
    });
  });

  describe('when multiple error packages are present', () => {
    const multipleErrorPackages = errorPackagesListQuery({
      extend: {
        count: 2,
        nodes: [firstPackage, secondPackage],
      },
    });

    describe('should display an alert', () => {
      beforeEach(async () => {
        mountComponent({
          resolver: jest.fn().mockResolvedValue(multipleErrorPackages),
        });
        await waitForPromises();
      });

      it('with count of packages in the title', () => {
        expect(findErrorPackageAlert().props('title')).toBe(
          'There was an error publishing 2 packages',
        );
      });

      it('with count of packages in the body', () => {
        expect(findErrorPackageAlert().text()).toBe(
          'Failed to publish 2 packages. Delete these packages and try again.',
        );
      });
    });

    describe('`Show packages with errors` button', () => {
      beforeEach(async () => {
        setWindowLocation(`${TEST_HOST}/foo?type=maven&after=1234`);
        mountComponent({
          resolver: jest.fn().mockResolvedValue(multipleErrorPackages),
          stubs: { GlAlert },
        });
        await waitForPromises();
      });

      it('is shown with correct href within the alert', () => {
        expect(findErrorAlertButton().text()).toBe('Show packages with errors');
        expect(findErrorAlertButton().attributes('href')).toBe(`${TEST_HOST}/foo?status=error`);
      });

      it('has tracking attributes', () => {
        expect(findErrorAlertButton().attributes()).toMatchObject({
          'data-event-tracking': 'click_show_packages_with_errors_link',
          'data-event-label': 'package_errors_alert',
        });
      });
    });
  });
});
