import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import DependencyProxyUsage from '~/usage_quotas/storage/namespace/components/dependency_proxy_usage.vue';

describe('Dependency proxy usage component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const defaultProps = {
    dependencyProxyTotalSize: 512,
  };

  const defaultProvide = {
    glFeatures: {
      virtualRegistryMaven: true,
    },
  };

  const findDependencyProxySizeSection = () =>
    wrapper.findByTestId('dependency-proxy-size-content');

  const createComponent = ({ provide = defaultProvide, props = {} } = {}) => {
    wrapper = shallowMountExtended(DependencyProxyUsage, {
      provide,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays the dependency proxy size section when prop is provided', () => {
    expect(findDependencyProxySizeSection().props('value')).toBe(
      defaultProps.dependencyProxyTotalSize,
    );
  });

  describe('when `dependencyProxyTotalSize` has BigInt value', () => {
    const mockDependencyProxyTotalSize = Number.MAX_SAFE_INTEGER;

    beforeEach(() => {
      createComponent({
        props: {
          dependencyProxyTotalSize: mockDependencyProxyTotalSize,
        },
      });
    });

    it('displays the dependency proxy size section when prop is provided', () => {
      expect(findDependencyProxySizeSection().props('value')).toBe(Number.MAX_SAFE_INTEGER);
    });
  });

  it('displays the description section', () => {
    const descriptionWrapper = wrapper.findByTestId('dependency-proxy-description');
    const moreInformationComponent = descriptionWrapper.findComponent(HelpPageLink);

    expect(descriptionWrapper.text()).toMatchInterpolatedText(
      'Cache for frequently-accessed Docker images and packages. More information',
    );
    expect(moreInformationComponent.text()).toBe('More information');
    expect(moreInformationComponent.props('href')).toBe('user/packages/dependency_proxy/_index');
  });

  describe('when feature flag virtualRegistryMaven is disabled', () => {
    it('displays the dependency proxy description section', () => {
      createComponent({
        provide: {
          ...defaultProvide,
          glFeatures: { virtualRegistryMaven: false },
        },
      });

      const descriptionWrapper = wrapper.findByTestId('dependency-proxy-description');

      expect(descriptionWrapper.text()).toMatchInterpolatedText(
        'Local proxy used for frequently-accessed upstream Docker images. More information',
      );
    });
  });
});
