import { mount } from '@vue/test-utils';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';

describe('PackagesListLoader', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(PackagesListLoader, {
      propsData: {
        ...props,
      },
    });
  };

  const findDesktopShapes = () => wrapper.find('[data-testid="desktop-loader"]');
  const findMobileShapes = () => wrapper.find('[data-testid="mobile-loader"]');

  beforeEach(createComponent);

  describe('desktop loader', () => {
    it('produces the right loader', () => {
      expect(findDesktopShapes().findAll('rect[width="1000"]')).toHaveLength(20);
    });

    it('has the correct classes', () => {
      expect(findDesktopShapes().classes()).toEqual(['gl-hidden', 'gl-flex-col', 'sm:gl-flex']);
    });
  });

  describe('mobile loader', () => {
    it('produces the right loader', () => {
      expect(findMobileShapes().findAll('rect[height="170"]')).toHaveLength(5);
    });

    it('has the correct classes', () => {
      expect(findMobileShapes().classes()).toEqual(['gl-flex-col', 'sm:gl-hidden']);
    });
  });
});
