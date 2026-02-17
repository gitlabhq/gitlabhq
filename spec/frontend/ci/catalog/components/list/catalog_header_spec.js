import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CatalogHeader from '~/ci/catalog/components/list/catalog_header.vue';

describe('CatalogHeader', () => {
  let wrapper;

  const defaultProps = {};
  const customProvide = {
    pageTitle: 'Catalog page',
    pageDescription: 'This is a nice catalog page',
    legalDisclaimer: '',
  };

  const findTitle = () => wrapper.find('h1');
  const findDescription = () => wrapper.findByTestId('page-description');
  const findLegalDisclaimer = () => wrapper.findByTestId('legal-disclaimer');

  const createComponent = ({ props = {}, provide = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(CatalogHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide,
      stubs: {
        ...stubs,
      },
    });
  };

  describe('title and description', () => {
    describe('when there are no values provided', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the default values', () => {
        expect(findTitle().text()).toBe('CI/CD Catalog');
        expect(findDescription().text()).toBe(
          'Discover CI/CD components that can improve your pipeline with additional functionality.',
        );
      });
    });

    describe('when custom values are provided', () => {
      beforeEach(() => {
        createComponent({ provide: customProvide });
      });

      it('renders the custom values', () => {
        expect(findTitle().text()).toBe(customProvide.pageTitle);
        expect(findDescription().text()).toBe(customProvide.pageDescription);
      });
    });
  });

  describe('legal disclaimer', () => {
    it('is rendered if provided', () => {
      const legalDisclaimer = 'legal disclaimer';
      createComponent({ provide: { ...customProvide, legalDisclaimer } });

      expect(findLegalDisclaimer().text()).toBe(legalDisclaimer);
    });

    it('is not rendered if not provided', () => {
      createComponent();

      expect(findLegalDisclaimer().exists()).toBe(false);
    });
  });
});
