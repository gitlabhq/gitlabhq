import { GlBanner, GlButton } from '@gitlab/ui';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CatalogHeader from '~/ci/catalog/components/list/catalog_header.vue';
import { CATALOG_FEEDBACK_DISMISSED_KEY } from '~/ci/catalog/constants';

describe('CatalogHeader', () => {
  useLocalStorageSpy();

  let wrapper;

  const defaultProps = {};
  const customProvide = {
    pageTitle: 'Catalog page',
    pageDescription: 'This is a nice catalog page',
  };

  const findBanner = () => wrapper.findComponent(GlBanner);
  const findFeedbackButton = () => findBanner().findComponent(GlButton);
  const findTitle = () => wrapper.find('h1');
  const findDescription = () => wrapper.findByTestId('page-description');

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

  describe('Feedback banner', () => {
    describe('when user has never dismissed', () => {
      beforeEach(() => {
        createComponent({ stubs: { GlBanner } });
      });

      it('is visible', () => {
        expect(findBanner().exists()).toBe(true);
      });

      it('has link to feedback issue', () => {
        expect(findFeedbackButton().attributes().href).toBe(
          'https://gitlab.com/gitlab-org/gitlab/-/issues/407556',
        );
      });
    });

    describe('when user dismisses it', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets the local storage and removes the banner', async () => {
        expect(findBanner().exists()).toBe(true);

        await findBanner().vm.$emit('close');

        expect(localStorage.setItem).toHaveBeenCalledWith(CATALOG_FEEDBACK_DISMISSED_KEY, 'true');
        expect(findBanner().exists()).toBe(false);
      });
    });

    describe('when user has dismissed it before', () => {
      beforeEach(() => {
        localStorage.setItem(CATALOG_FEEDBACK_DISMISSED_KEY, 'true');
        createComponent();
      });

      it('does not show the banner', () => {
        expect(findBanner().exists()).toBe(false);
      });
    });
  });
});
