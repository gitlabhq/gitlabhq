import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import DependencyProxyUsage from '~/usage_quotas/storage/components/dependency_proxy_usage.vue';

describe('Dependency proxy usage component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const defaultProps = {
    dependencyProxyTotalSize: 512,
  };

  const findDependencyProxySizeSection = () => wrapper.findByTestId('dependency-proxy-size');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DependencyProxyUsage, {
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
      'Local proxy used for frequently-accessed upstream Docker images. More information',
    );
    expect(moreInformationComponent.text()).toBe('More information');
    expect(moreInformationComponent.props('href')).toBe('user/packages/dependency_proxy/index');
  });
});
