import { mount } from '@vue/test-utils';
import PackagesListLoader from '~/packages/shared/components/packages_list_loader.vue';

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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('desktop loader', () => {
    it('produces the right loader', () => {
      expect(findDesktopShapes().findAll('rect[width="1000"]')).toHaveLength(20);
    });

    it('has the correct classes', () => {
      expect(findDesktopShapes().classes()).toEqual([
        'gl-display-none',
        'gl-sm-display-flex',
        'gl-flex-direction-column',
      ]);
    });
  });

  describe('mobile loader', () => {
    it('produces the right loader', () => {
      expect(findMobileShapes().findAll('rect[height="170"]')).toHaveLength(5);
    });

    it('has the correct classes', () => {
      expect(findMobileShapes().classes()).toEqual([
        'gl-flex-direction-column',
        'gl-sm-display-none',
      ]);
    });
  });
});
