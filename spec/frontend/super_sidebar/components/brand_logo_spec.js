import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import * as touchDetection from '~/lib/utils/touch_detection';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';

describe('Brand Logo component', () => {
  let wrapper;

  const defaultPropsData = {
    logoUrl: 'path/to/logo',
  };

  const findBrandLogo = () => wrapper.findByTestId('brand-header-custom-logo');
  const findDefaultLogo = () => wrapper.findByTestId('brand-header-default-logo');
  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(BrandLogo, {
      provide: {
        rootPath: '/',
      },
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('basic functionality', () => {
    it('renders it', () => {
      createWrapper();
      expect(findBrandLogo().exists()).toBe(true);
      expect(findBrandLogo().element.src).toBe(defaultPropsData.logoUrl);
    });

    it('when logoUrl given empty', () => {
      createWrapper({ logoUrl: '' });

      expect(findBrandLogo().exists()).toBe(false);
      expect(findDefaultLogo().exists()).toBe(true);
    });
  });

  describe('tooltip behavior', () => {
    beforeEach(() => {
      jest.spyOn(touchDetection, 'hasTouchCapability');
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('shows homepage tooltip on non-touch devices', () => {
      touchDetection.hasTouchCapability.mockReturnValue(false);
      createWrapper();

      expect(getTooltip()).toBe('Homepage');
    });

    it('hides homepage tooltip on touch devices', () => {
      touchDetection.hasTouchCapability.mockReturnValue(true);
      createWrapper();

      expect(getTooltip()).toBeNull();
    });

    it('calls hasTouchCapability when computing tooltip', () => {
      touchDetection.hasTouchCapability.mockReturnValue(false);
      createWrapper();

      expect(getTooltip()).toBe('Homepage');
      expect(touchDetection.hasTouchCapability).toHaveBeenCalled();
    });
  });
});
