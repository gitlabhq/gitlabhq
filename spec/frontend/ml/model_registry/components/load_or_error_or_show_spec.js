import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';

describe('ml/model_registry/components/load_or_error_or_show.vue', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoader = () => wrapper.findComponent(PackagesListLoader);

  const mountComponent = (isLoading, errorMessage) => {
    wrapper = shallowMountExtended(LoadOrErrorOrShow, {
      propsData: {
        isLoading,
        errorMessage,
      },
      slots: {
        default: 'Some content',
      },
    });
  };

  describe('When is loading', () => {
    it('shows loading state', () => {
      mountComponent(true, '');

      expect(findLoader().exists()).toBe(true);
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('When has error', () => {
    it('shows error message', () => {
      mountComponent(false, 'Some error');

      expect(findLoader().exists()).toBe(false);
      expect(findAlert().text()).toContain('Some error');
    });
  });

  describe('When has no error and is not loading', () => {
    it('shows content', () => {
      mountComponent(false, '');

      expect(findLoader().exists()).toBe(false);
      expect(findAlert().exists()).toBe(false);
      expect(wrapper.text()).toContain('Some content');
    });
  });
});
