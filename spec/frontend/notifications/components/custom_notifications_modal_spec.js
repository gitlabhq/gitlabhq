import { GlSprintf, GlModal, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import CustomNotificationsModal from '~/notifications/components/custom_notifications_modal.vue';

const mockNotificationSettingsResponses = {
  default: {
    level: 'custom',
    events: {
      new_release: true,
      new_note: false,
    },
  },
  updated: {
    level: 'custom',
    events: {
      new_release: true,
      new_note: true,
    },
  },
  defaultWithUknownEvent: {
    level: 'custom',
    events: {
      new_release: true,
      new_note: false,
      event_without_frontend_translation: true,
    },
  },
};

const mockToastShow = jest.fn();

describe('CustomNotificationsModal', () => {
  let wrapper;
  let mockAxios;

  function createComponent(options = {}) {
    const { injectedProperties = {}, props = {} } = options;
    return extendedWrapper(
      shallowMount(CustomNotificationsModal, {
        propsData: {
          ...props,
        },
        provide: {
          ...injectedProperties,
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
        stubs: {
          GlModal,
          GlToggle,
        },
      }),
    );
  }

  const findModalBodyDescription = () => wrapper.findComponent(GlSprintf);
  const findAllToggles = () => wrapper.findAllComponents(GlToggle);
  const findToggleAt = (index) => findAllToggles().at(index);
  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    gon.api_version = 'v4';
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the title and the body message', () => {
      expect(findModal().text()).toBe('Custom notification events');
      expect(findModalBodyDescription().attributes('message')).toBe(
        'With custom notification levels you receive notifications for the same events as in the Participate level, with additional selected events. For more information, see %{notificationLinkStart}notification emails%{notificationLinkEnd}.',
      );
    });

    it('renders a modal without a footer', () => {
      const modal = findModal();
      expect(modal.props('actionCancel')).toBeNull();
      expect(modal.props('actionPrimary')).toBeNull();
    });

    describe('toggle items', () => {
      beforeEach(async () => {
        const endpointUrl = '/api/v4/notification_settings';

        mockAxios
          .onGet(endpointUrl)
          .reply(HTTP_STATUS_OK, mockNotificationSettingsResponses.defaultWithUknownEvent);

        wrapper = createComponent();

        wrapper.findComponent(GlModal).vm.$emit('show');

        await waitForPromises();
      });

      it.each`
        index | eventId          | eventName               | enabled  | loading
        ${0}  | ${'new_note'}    | ${'Comment is added'}   | ${false} | ${false}
        ${1}  | ${'new_release'} | ${'Release is created'} | ${true}  | ${false}
      `(
        'renders a toggle for "$eventName" with value=$enabled',
        ({ index, eventName, enabled, loading }) => {
          const toggle = findToggleAt(index);
          expect(toggle.props('label')).toBe(eventName);
          expect(toggle.props('value')).toBe(enabled);
          expect(toggle.props('isLoading')).toBe(loading);
        },
      );

      it('only renders toggles for events with a known translation', () => {
        expect(findAllToggles()).toHaveLength(2);
      });
    });
  });

  describe('API calls', () => {
    describe('load notification settings', () => {
      beforeEach(() => {
        jest.spyOn(axios, 'get');
      });

      it.each`
        projectId | groupId | endpointUrl                                   | notificationType | condition
        ${1}      | ${null} | ${'/api/v4/projects/1/notification_settings'} | ${'project'}     | ${'a projectId is given'}
        ${null}   | ${1}    | ${'/api/v4/groups/1/notification_settings'}   | ${'group'}       | ${'a groupId is given'}
        ${null}   | ${null} | ${'/api/v4/notification_settings'}            | ${'global'}      | ${'neither projectId nor groupId are given'}
      `(
        'requests $notificationType notification settings when $condition',
        async ({ projectId, groupId, endpointUrl }) => {
          const injectedProperties = {
            projectId,
            groupId,
          };

          mockAxios
            .onGet(endpointUrl)
            .reply(HTTP_STATUS_OK, mockNotificationSettingsResponses.default);

          wrapper = createComponent({ injectedProperties });

          wrapper.findComponent(GlModal).vm.$emit('show');

          await waitForPromises();

          expect(axios.get).toHaveBeenCalledWith(endpointUrl);
        },
      );

      it('updates the loading state and the events property', async () => {
        const endpointUrl = '/api/v4/notification_settings';

        mockAxios
          .onGet(endpointUrl)
          .reply(HTTP_STATUS_OK, mockNotificationSettingsResponses.default);

        wrapper = createComponent();

        wrapper.findComponent(GlModal).vm.$emit('show');
        expect(wrapper.vm.isLoading).toBe(true);

        await waitForPromises();

        expect(axios.get).toHaveBeenCalledWith(endpointUrl);
        expect(wrapper.vm.isLoading).toBe(false);
        expect(wrapper.vm.events).toEqual([
          { id: 'new_note', enabled: false, name: 'Comment is added', loading: false },
          { id: 'new_release', enabled: true, name: 'Release is created', loading: false },
        ]);
      });

      it('shows a toast message when the request fails', async () => {
        mockAxios.onGet('/api/v4/notification_settings').reply(HTTP_STATUS_NOT_FOUND, {});
        wrapper = createComponent();

        wrapper.findComponent(GlModal).vm.$emit('show');

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          'An error occurred while loading the notification settings. Please try again.',
        );
      });
    });

    describe('update notification settings', () => {
      beforeEach(() => {
        jest.spyOn(axios, 'put');
      });

      it.each`
        projectId | groupId | endpointUrl                                   | notificationType | condition
        ${1}      | ${null} | ${'/api/v4/projects/1/notification_settings'} | ${'project'}     | ${'a projectId is given'}
        ${null}   | ${1}    | ${'/api/v4/groups/1/notification_settings'}   | ${'group'}       | ${'a groupId is given'}
        ${null}   | ${null} | ${'/api/v4/notification_settings'}            | ${'global'}      | ${'neither projectId nor groupId are given'}
      `(
        'updates the $notificationType notification settings when $condition and the user toggles an event',
        async ({ projectId, groupId, endpointUrl }) => {
          mockAxios
            .onGet(endpointUrl)
            .reply(HTTP_STATUS_OK, mockNotificationSettingsResponses.default);

          mockAxios
            .onPut(endpointUrl)
            .reply(HTTP_STATUS_OK, mockNotificationSettingsResponses.updated);

          const injectedProperties = {
            projectId,
            groupId,
          };

          wrapper = createComponent({ injectedProperties });

          wrapper.findComponent(GlModal).vm.$emit('show');

          await waitForPromises();

          findToggleAt(0).vm.$emit('change', true);

          await waitForPromises();

          expect(axios.put).toHaveBeenCalledWith(endpointUrl, {
            new_note: true,
          });

          expect(wrapper.vm.events).toEqual([
            { id: 'new_note', enabled: true, name: 'Comment is added', loading: false },
            { id: 'new_release', enabled: true, name: 'Release is created', loading: false },
          ]);
        },
      );

      it('shows a toast message when the request fails', async () => {
        const endpointUrl = '/api/v4/notification_settings';

        mockAxios
          .onGet(endpointUrl)
          .reply(HTTP_STATUS_OK, mockNotificationSettingsResponses.default);

        mockAxios.onPut(endpointUrl).reply(HTTP_STATUS_NOT_FOUND, {});
        wrapper = createComponent();

        wrapper.findComponent(GlModal).vm.$emit('show');

        await waitForPromises();

        findToggleAt(1).vm.$emit('change', true);

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          'An error occurred while updating the notification settings. Please try again.',
        );
      });
    });
  });
});
