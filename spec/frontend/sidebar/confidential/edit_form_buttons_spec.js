import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import EditFormButtons from '~/sidebar/components/confidential/edit_form_buttons.vue';
import eventHub from '~/sidebar/event_hub';
import createStore from '~/notes/stores';
import waitForPromises from 'helpers/wait_for_promises';
import flash from '~/flash';

jest.mock('~/sidebar/event_hub', () => ({ $emit: jest.fn() }));
jest.mock('~/flash');

describe('Edit Form Buttons', () => {
  let wrapper;
  let store;
  const findConfidentialToggle = () => wrapper.find('[data-testid="confidential-toggle"]');

  const createComponent = ({
    props = {},
    data = {},
    confidentialApolloSidebar = false,
    resolved = true,
  }) => {
    store = createStore();
    if (resolved) {
      jest.spyOn(store, 'dispatch').mockResolvedValue();
    } else {
      jest.spyOn(store, 'dispatch').mockRejectedValue();
    }

    wrapper = shallowMount(EditFormButtons, {
      propsData: {
        fullPath: '',
        ...props,
      },
      data() {
        return {
          isLoading: true,
          ...data,
        };
      },
      provide: {
        glFeatures: {
          confidentialApolloSidebar,
        },
      },
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when isLoading', () => {
    beforeEach(() => {
      createComponent({});

      wrapper.vm.$store.state.noteableData.confidential = false;
    });

    it('renders "Applying" in the toggle button', () => {
      expect(findConfidentialToggle().text()).toBe('Applying');
    });

    it('disables the toggle button', () => {
      expect(findConfidentialToggle().attributes('disabled')).toBe('disabled');
    });

    it('finds the GlLoadingIcon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when not confidential', () => {
    it('renders Turn On in the toggle button', () => {
      createComponent({
        data: {
          isLoading: false,
        },
      });

      expect(findConfidentialToggle().text()).toBe('Turn On');
    });
  });

  describe('when confidential', () => {
    beforeEach(() => {
      createComponent({
        data: {
          isLoading: false,
        },
      });

      wrapper.vm.$store.state.noteableData.confidential = true;
    });

    it('renders on or off text based on confidentiality', () => {
      expect(findConfidentialToggle().text()).toBe('Turn Off');
    });

    describe('when clicking on the confidential toggle', () => {
      it('emits updateConfidentialAttribute', () => {
        findConfidentialToggle().trigger('click');

        expect(eventHub.$emit).toHaveBeenCalledWith('updateConfidentialAttribute');
      });
    });
  });

  describe('when confidentialApolloSidebar is turned on', () => {
    const isConfidential = true;

    describe('when succeeds', () => {
      beforeEach(() => {
        createComponent({ data: { isLoading: false }, confidentialApolloSidebar: true });
        wrapper.vm.$store.state.noteableData.confidential = isConfidential;
        findConfidentialToggle().trigger('click');
      });

      it('dispatches the correct action', () => {
        expect(store.dispatch).toHaveBeenCalledWith('updateConfidentialityOnIssue', {
          confidential: !isConfidential,
          fullPath: '',
        });
      });

      it('resets loading', () => {
        return waitForPromises().then(() => {
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        });
      });

      it('emits close form', () => {
        return waitForPromises().then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('closeConfidentialityForm');
        });
      });
    });

    describe('when fails', () => {
      beforeEach(() => {
        createComponent({
          data: { isLoading: false },
          confidentialApolloSidebar: true,
          resolved: false,
        });
        wrapper.vm.$store.state.noteableData.confidential = isConfidential;
        findConfidentialToggle().trigger('click');
      });

      it('calls flash with the correct message', () => {
        expect(flash).toHaveBeenCalledWith(
          'Something went wrong trying to change the confidentiality of this issue',
        );
      });
    });
  });
});
