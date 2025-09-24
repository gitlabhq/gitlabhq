import { mountExtended } from 'helpers/vue_test_utils_helper';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';

describe('PackagesListLoader', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(PackagesListLoader);
  };

  const findDesktopShapes = () => wrapper.findByTestId('desktop-loader');
  const findMobileShapes = () => wrapper.findByTestId('mobile-loader');

  beforeEach(createComponent);

  describe('desktop loader', () => {
    it('produces the right loader', () => {
      expect(findDesktopShapes().findAll('rect[width="1000"]')).toHaveLength(10);
    });

    it('has the correct classes', () => {
      expect(findDesktopShapes().classes()).toEqual([
        'gl-mb-5',
        'gl-hidden',
        'gl-flex-col',
        '@sm/panel:gl-flex',
      ]);
    });
  });

  describe('mobile loader', () => {
    it('produces the right loader', () => {
      expect(findMobileShapes().findAll('rect[height="95"]')).toHaveLength(5);
    });

    it('has the correct classes', () => {
      expect(findMobileShapes().classes()).toEqual(['gl-flex-col', '@sm/panel:gl-hidden']);
    });
  });
});
