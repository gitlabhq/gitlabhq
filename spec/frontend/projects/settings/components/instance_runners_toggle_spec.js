import { GlLink, GlSprintf, GlToggle } from '@gitlab/ui';
import MockAxiosAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import InstanceRunnersToggle from '~/projects/settings/components/instance_runners_toggle.vue';

const TEST_UPDATE_PATH = '/test/update_instance_runners';
const mockParentName = 'My group';
const mockGroupSettingsPath = '/groups/my-group/-/settings/ci_cd';

jest.mock('~/alert');

describe('InstanceRunnersToggle', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(InstanceRunnersToggle, {
      propsData: {
        isEnabled: false,
        isDisabledAndUnoverridable: false,
        isLoading: false,
        updatePath: TEST_UPDATE_PATH,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findUnoverridableAlert = () => wrapper.findByTestId('unoverridable-alert');
  const findInstanceRunnersToggle = () => wrapper.findComponent(GlToggle);
  const getToggleValue = () => findInstanceRunnersToggle().props('value');
  const isToggleLoading = () => findInstanceRunnersToggle().props('isLoading');
  const isToggleDisabled = () => findInstanceRunnersToggle().props('disabled');

  beforeEach(() => {
    mockAxios = new MockAxiosAdapter(axios);
    mockAxios.onPost(TEST_UPDATE_PATH).reply(HTTP_STATUS_OK);
  });

  afterEach(() => {
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

    it('renders text explaining why the toggle is disabled', () => {
      expect(findInstanceRunnersToggle().text()).toContain(
        'Instance runners are disabled in the group settings.',
      );
    });

    describe('when user can configure group', () => {
      beforeEach(() => {
        createComponent({
          isDisabledAndUnoverridable: true,
          groupName: mockParentName,
          groupSettingsPath: mockGroupSettingsPath,
        });
      });

      it('renders link to enable', () => {
        expect(findInstanceRunnersToggle().text()).toContain(
          `Go to ${mockParentName} to enable them.`,
        );

        const link = findInstanceRunnersToggle().findComponent(GlLink);
        expect(link.text()).toBe(mockParentName);
        expect(link.attributes('href')).toBe(mockGroupSettingsPath);
      });
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
      expect(findUnoverridableAlert().exists()).toBe(false);
    });

    describe('with instance runners DISABLED', () => {
      beforeEach(() => {
        createComponent();
      });

      it('toggle should be turned off', () => {
        expect(getToggleValue()).toBe(false);
      });

      it('can enable toggle', async () => {
        findInstanceRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(mockAxios.history.post[0].data).toEqual(undefined);
        expect(mockAxios.history.post).toHaveLength(1);
        expect(findErrorAlert().exists()).toBe(false);
        expect(getToggleValue()).toBe(true);
        expect(wrapper.emitted('change')).toEqual([[true]]);
      });
    });

    describe('with instance runners ENABLED', () => {
      beforeEach(() => {
        createComponent({ isEnabled: true });
      });

      it('toggle should be turned on', () => {
        expect(getToggleValue()).toBe(true);
      });

      it('can disable toggle', async () => {
        findInstanceRunnersToggle().vm.$emit('change', false);
        await waitForPromises();

        expect(mockAxios.history.post[0].data).toEqual(undefined);
        expect(mockAxios.history.post).toHaveLength(1);
        expect(findErrorAlert().exists()).toBe(false);
        expect(getToggleValue()).toBe(false);
        expect(wrapper.emitted('change')).toEqual([[false]]);
      });
    });

    describe('loading icon', () => {
      it('should show and hide on request', async () => {
        createComponent();
        expect(isToggleLoading()).toBe(false);

        findInstanceRunnersToggle().vm.$emit('change', true);
        await nextTick();
        expect(isToggleLoading()).toBe(true);

        await waitForPromises();
        expect(isToggleLoading()).toBe(false);
      });
    });

    describe('when request encounters an error', () => {
      it('should show custom error message from API if it exists', async () => {
        mockAxios
          .onPost(TEST_UPDATE_PATH)
          .reply(HTTP_STATUS_UNAUTHORIZED, { error: 'Custom API Error message' });
        createComponent();
        expect(getToggleValue()).toBe(false);

        findInstanceRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(findErrorAlert().text()).toBe('Custom API Error message');
        expect(getToggleValue()).toBe(false); // toggle value should not change
      });

      it('should show default error message if API does not return a custom error message', async () => {
        mockAxios.onPost(TEST_UPDATE_PATH).reply(HTTP_STATUS_UNAUTHORIZED);
        createComponent();
        expect(getToggleValue()).toBe(false);

        findInstanceRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(findErrorAlert().text()).toBe('An error occurred while updating the configuration.');
        expect(getToggleValue()).toBe(false); // toggle value should not change
      });
    });
  });
});
