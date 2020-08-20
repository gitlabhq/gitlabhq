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

  const getShapes = () => wrapper.vm.desktopShapes;
  const findSquareButton = () => wrapper.find({ ref: 'button-loader' });

  beforeEach(createComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when used for projects', () => {
    it('should return 5 rects with last one being a square', () => {
      expect(getShapes()).toHaveLength(5);
      expect(findSquareButton().exists()).toBe(true);
    });
  });

  describe('when used for groups', () => {
    beforeEach(() => {
      createComponent({ isGroup: true });
    });

    it('should return 5 rects with no square', () => {
      expect(getShapes()).toHaveLength(5);
      expect(findSquareButton().exists()).toBe(false);
    });
  });
});
