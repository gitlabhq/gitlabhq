import { GlBanner, GlButton } from '@gitlab/ui';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CatalogHeader from '~/ci/catalog/components/list/catalog_header.vue';
import { CATALOG_FEEDBACK_DISMISSED_KEY } from '~/ci/catalog/constants';

describe('CatalogHeader', () => {
  useLocalStorageSpy();

  let wrapper;

  const defaultProps = {};
  const defaultProvide = {
    pageTitle: 'Catalog page',
    pageDescription: 'This is a nice catalog page',
  };

  const findBanner = () => wrapper.findComponent(GlBanner);
  const findFeedbackButton = () => findBanner().findComponent(GlButton);
  const findTitle = () => wrapper.findByText(defaultProvide.pageTitle);
  const findDescription = () => wrapper.findByText(defaultProvide.pageDescription);

  const createComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(CatalogHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: defaultProvide,
      stubs: {
        ...stubs,
      },
    });
  };

  it('renders the Catalog title and description', () => {
    createComponent();

    expect(findTitle().exists()).toBe(true);
    expect(findDescription().exists()).toBe(true);
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
