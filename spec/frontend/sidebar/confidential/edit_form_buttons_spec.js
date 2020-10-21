import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import EditFormButtons from '~/sidebar/components/confidential/edit_form_buttons.vue';
import eventHub from '~/sidebar/event_hub';
import createStore from '~/notes/stores';
import { deprecatedCreateFlash as flash } from '~/flash';

jest.mock('~/sidebar/event_hub', () => ({ $emit: jest.fn() }));
jest.mock('~/flash');

describe('Edit Form Buttons', () => {
  let wrapper;
  let store;
  const findConfidentialToggle = () => wrapper.find('[data-testid="confidential-toggle"]');

  const createComponent = ({ props = {}, data = {}, resolved = true }) => {
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
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when isLoading', () => {
    beforeEach(() => {
      createComponent({
        props: {
          confidential: false,
        },
      });
    });

    it('renders "Applying" in the toggle button', () => {
      expect(findConfidentialToggle().text()).toBe('Applying');
    });

    it('disables the toggle button', () => {
      expect(findConfidentialToggle().props('disabled')).toBe(true);
    });

    it('sets loading on the toggle button', () => {
      expect(findConfidentialToggle().props('loading')).toBe(true);
    });
  });

  describe('when not confidential', () => {
    it('renders Turn On in the toggle button', () => {
      createComponent({
        data: {
          isLoading: false,
        },
        props: {
          confidential: false,
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
        props: {
          confidential: true,
        },
      });
    });

    it('renders on or off text based on confidentiality', () => {
      expect(findConfidentialToggle().text()).toBe('Turn Off');
    });
  });

  describe('when succeeds', () => {
    beforeEach(() => {
      createComponent({ data: { isLoading: false }, props: { confidential: true } });
      findConfidentialToggle().vm.$emit('click', new Event('click'));
    });

    it('dispatches the correct action', () => {
      expect(store.dispatch).toHaveBeenCalledWith('updateConfidentialityOnIssuable', {
        confidential: false,
        fullPath: '',
      });
    });

    it('resets loading on the toggle button', () => {
      return waitForPromises().then(() => {
        expect(findConfidentialToggle().props('loading')).toBe(false);
      });
    });

    it('emits close form', () => {
      return waitForPromises().then(() => {
        expect(eventHub.$emit).toHaveBeenCalledWith('closeConfidentialityForm');
      });
    });

    it('emits updateOnConfidentiality event', () => {
      return waitForPromises().then(() => {
        expect(eventHub.$emit).toHaveBeenCalledWith('updateIssuableConfidentiality', false);
      });
    });
  });

  describe('when fails', () => {
    beforeEach(() => {
      createComponent({
        data: { isLoading: false },
        props: { confidential: true },
        resolved: false,
      });
      findConfidentialToggle().vm.$emit('click', new Event('click'));
    });

    it('calls flash with the correct message', () => {
      expect(flash).toHaveBeenCalledWith(
        'Something went wrong trying to change the confidentiality of this issue',
      );
    });
  });
});
