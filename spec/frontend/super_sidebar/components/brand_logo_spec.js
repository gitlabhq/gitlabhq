import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';

describe('Brand Logo component', () => {
  let wrapper;

  const defaultPropsData = {
    logoUrl: 'path/to/logo',
  };

  const findBrandLogo = () => wrapper.findByTestId('brand-header-custom-logo');
  const findDefaultLogo = () => wrapper.findByTestId('brand-header-default-logo');

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
