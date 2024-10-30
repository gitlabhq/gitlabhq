import { nextTick } from 'vue';
import { GlAlert, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'spec/test_constants';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import PackageErrorsCount from '~/packages_and_registries/package_registry/components/list/package_errors_count.vue';
import { packageData } from '../../mock_data';

describe('PackageErrorsCount', () => {
  let wrapper;

  const firstPackage = packageData();
  const errorPackage = {
    ...packageData(),
    id: 'gid://gitlab/Packages::Package/121',
    status: 'ERROR',
    name: 'error package',
  };

  const findDeletePackagesModal = () => wrapper.findComponent(DeleteModal);
  const findErrorPackageAlert = () => wrapper.findComponent(GlAlert);
  const findErrorAlertButton = () => findErrorPackageAlert().findComponent(GlButton);

  const showMock = jest.fn();

  const mountComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(PackageErrorsCount, {
      propsData: {
        ...props,
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

  describe('when an error package is present', () => {
    beforeEach(() => {
      mountComponent({ props: { errorPackages: [errorPackage] } });
    });

    it('should display an alert with default body message', () => {
      expect(findErrorPackageAlert().exists()).toBe(true);
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing error package',
      );
      expect(findErrorPackageAlert().text()).toBe(
        'There was a timeout and the package was not published. Delete this package and try again.',
      );
    });

    it('should display alert body with message set in `statusMessage`', () => {
      mountComponent({
        props: {
          errorPackages: [{ ...errorPackage, statusMessage: 'custom error message' }],
        },
      });

      expect(findErrorPackageAlert().exists()).toBe(true);
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing error package',
      );
      expect(findErrorPackageAlert().text()).toBe('custom error message');
    });

    describe('`Delete this package` button', () => {
      beforeEach(() => {
        mountComponent({
          props: { errorPackages: [errorPackage] },
          stubs: { GlAlert },
        });
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

        expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual([errorPackage]);
      });

      describe('when modal confirms', () => {
        beforeEach(() => {
          findErrorAlertButton().vm.$emit('click');
          findDeletePackagesModal().vm.$emit('confirm');
        });

        it('emits delete when modal confirms', () => {
          expect(wrapper.emitted('confirm-delete')[0][0]).toEqual([errorPackage]);
        });
      });
    });
  });

  describe('when multiple error packages are present', () => {
    beforeEach(() => {
      mountComponent({
        props: { errorPackages: [{ ...firstPackage, status: errorPackage.status }, errorPackage] },
      });
    });

    it('should display an alert with default body message', () => {
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing 2 packages',
      );
      expect(findErrorPackageAlert().text()).toBe(
        'Failed to publish 2 packages. Delete these packages and try again.',
      );
    });

    describe('`Show packages with errors` button', () => {
      beforeEach(() => {
        setWindowLocation(`${TEST_HOST}/foo?type=maven&after=1234`);
        mountComponent({
          props: {
            errorPackages: [{ ...firstPackage, status: errorPackage.status }, errorPackage],
          },
          stubs: { GlAlert },
        });
      });

      it('is shown with correct href within the alert', () => {
        expect(findErrorAlertButton().text()).toBe('Show packages with errors');
        expect(findErrorAlertButton().attributes('href')).toBe(
          `${TEST_HOST}/foo?type=maven&status=error`,
        );
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
