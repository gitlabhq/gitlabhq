import { mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import Component from '~/vue_shared/components/dismissible_feedback_alert.vue';

describe('Dismissible Feedback Alert', () => {
  useLocalStorageSpy();

  let wrapper;

  const defaultProps = {
    featureName: 'Dependency List',
    feedbackLink: 'https://gitlab.link',
  };

  const STORAGE_DISMISSAL_KEY = 'dependency_list_feedback_dismissed';

  const createComponent = ({ props, shallow } = {}) => {
    const mountFn = shallow ? shallowMount : mount;

    wrapper = mountFn(Component, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findAlert = () => wrapper.find(GlAlert);
  const findLink = () => wrapper.find(GlLink);

  describe('with default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('contains feature name', () => {
      expect(findAlert().text()).toContain(defaultProps.featureName);
    });

    it('contains provided link', () => {
      const link = findLink();

      expect(link.attributes('href')).toBe(defaultProps.feedbackLink);
      expect(link.attributes('target')).toBe('_blank');
    });

    it('should have the storage key set', () => {
      expect(wrapper.vm.storageKey).toBe(STORAGE_DISMISSAL_KEY);
    });
  });

  describe('dismissible', () => {
    describe('after dismissal', () => {
      beforeEach(() => {
        createComponent({ shallow: false });
        findAlert().vm.$emit('dismiss');
      });

      it('hides the alert', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('should remember the dismissal state', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith(STORAGE_DISMISSAL_KEY, 'true');
      });
    });

    describe('already dismissed', () => {
      it('should not show the alert once dismissed', async () => {
        localStorage.setItem(STORAGE_DISMISSAL_KEY, 'true');
        createComponent({ shallow: false });
        await wrapper.vm.$nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});
