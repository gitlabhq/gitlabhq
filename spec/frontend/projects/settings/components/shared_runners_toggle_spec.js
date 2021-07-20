import { GlAlert, GlToggle, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAxiosAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import SharedRunnersToggleComponent from '~/projects/settings/components/shared_runners_toggle.vue';

const TEST_UPDATE_PATH = '/test/update_shared_runners';

jest.mock('~/flash');

describe('projects/settings/components/shared_runners', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SharedRunnersToggleComponent, {
      propsData: {
        isEnabled: false,
        isDisabledAndUnoverridable: false,
        isLoading: false,
        updatePath: TEST_UPDATE_PATH,
        isCreditCardValidationRequired: false,
        ...props,
      },
    });
  };

  const findErrorAlert = () => wrapper.find(GlAlert);
  const findSharedRunnersToggle = () => wrapper.find(GlToggle);
  const findToggleTooltip = () => wrapper.find(GlTooltip);
  const getToggleValue = () => findSharedRunnersToggle().props('value');
  const isToggleLoading = () => findSharedRunnersToggle().props('isLoading');
  const isToggleDisabled = () => findSharedRunnersToggle().props('disabled');

  beforeEach(() => {
    mockAxios = new MockAxiosAdapter(axios);
    mockAxios.onPost(TEST_UPDATE_PATH).reply(200);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.restore();
  });

  describe('with group share settings DISABLED', () => {
    beforeEach(() => {
      createComponent({
        isDisabledAndUnoverridable: true,
      });
    });

    it('toggle should be disabled', () => {
      expect(isToggleDisabled()).toBe(true);
    });

    it('tooltip should exist explaining why the toggle is disabled', () => {
      expect(findToggleTooltip().exists()).toBe(true);
    });
  });

  describe('with group share settings ENABLED', () => {
    beforeEach(() => {
      createComponent();
    });

    it('toggle should be enabled', () => {
      expect(isToggleDisabled()).toBe(false);
    });

    it('loading icon, error message, and tooltip should not exist', () => {
      expect(isToggleLoading()).toBe(false);
      expect(findErrorAlert().exists()).toBe(false);
      expect(findToggleTooltip().exists()).toBe(false);
    });

    describe('with shared runners DISABLED', () => {
      beforeEach(() => {
        createComponent();
      });

      it('toggle should be turned off', () => {
        expect(getToggleValue()).toBe(false);
      });

      it('can enable toggle', async () => {
        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(mockAxios.history.post[0].data).toEqual(undefined);
        expect(mockAxios.history.post).toHaveLength(1);
        expect(findErrorAlert().exists()).toBe(false);
        expect(getToggleValue()).toBe(true);
      });
    });

    describe('with shared runners ENABLED', () => {
      beforeEach(() => {
        createComponent({ isEnabled: true });
      });

      it('toggle should be turned on', () => {
        expect(getToggleValue()).toBe(true);
      });

      it('can disable toggle', async () => {
        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(mockAxios.history.post[0].data).toEqual(undefined);
        expect(mockAxios.history.post).toHaveLength(1);
        expect(findErrorAlert().exists()).toBe(false);
        expect(getToggleValue()).toBe(false);
      });
    });

    describe('loading icon', () => {
      it('should show and hide on request', async () => {
        createComponent();
        expect(isToggleLoading()).toBe(false);

        findSharedRunnersToggle().vm.$emit('change', true);
        await wrapper.vm.$nextTick();
        expect(isToggleLoading()).toBe(true);

        await waitForPromises();
        expect(isToggleLoading()).toBe(false);
      });
    });

    describe('when request encounters an error', () => {
      it('should show custom error message from API if it exists', async () => {
        mockAxios.onPost(TEST_UPDATE_PATH).reply(401, { error: 'Custom API Error message' });
        createComponent();
        expect(getToggleValue()).toBe(false);

        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(findErrorAlert().text()).toBe('Custom API Error message');
        expect(getToggleValue()).toBe(false); // toggle value should not change
      });

      it('should show default error message if API does not return a custom error message', async () => {
        mockAxios.onPost(TEST_UPDATE_PATH).reply(401);
        createComponent();
        expect(getToggleValue()).toBe(false);

        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(findErrorAlert().text()).toBe('An error occurred while updating the configuration.');
        expect(getToggleValue()).toBe(false); // toggle value should not change
      });
    });
  });
});
