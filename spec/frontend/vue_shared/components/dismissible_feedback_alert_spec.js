import { GlAlert, GlSprintf } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import Component from '~/vue_shared/components/dismissible_feedback_alert.vue';

describe('Dismissible Feedback Alert', () => {
  useLocalStorageSpy();

  let wrapper;

  const featureName = 'Dependency List';
  const STORAGE_DISMISSAL_KEY = 'dependency_list_feedback_dismissed';

  const createComponent = ({ props, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(Component, {
      propsData: {
        featureName,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const createFullComponent = () => createComponent({ mountFn: mount });
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('with default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('should have the storage key set', () => {
      expect(wrapper.vm.storageKey).toBe(STORAGE_DISMISSAL_KEY);
    });
  });

  describe('with other attributes', () => {
    const mockTitle = 'My title';
    const mockVariant = 'warning';

    beforeEach(() => {
      createComponent({
        props: {
          title: mockTitle,
          variant: mockVariant,
        },
      });
    });

    it('passes props to alert', () => {
      expect(findAlert().props()).toMatchObject({
        title: mockTitle,
        variant: mockVariant,
      });
    });
  });

  describe('dismissible', () => {
    describe('after dismissal', () => {
      beforeEach(() => {
        createFullComponent();
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
        createFullComponent();
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});
