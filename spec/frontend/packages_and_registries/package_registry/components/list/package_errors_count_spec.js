import { GlAlert, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'spec/test_constants';
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

  const findErrorPackageAlert = () => wrapper.findComponent(GlAlert);
  const findErrorAlertButton = () => findErrorPackageAlert().findComponent(GlButton);

  const mountComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(PackageErrorsCount, {
      propsData: {
        ...props,
      },
      stubs: {
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

      it('when clicked emits `confirm-delete` event', () => {
        findErrorAlertButton().vm.$emit('click');

        expect(wrapper.emitted('confirm-delete')[0][0]).toStrictEqual([errorPackage]);
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
    });
  });
});
