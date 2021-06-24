import { GlSprintf, GlModal, GlFormGroup, GlFormCheckbox, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import httpStatus from '~/lib/utils/http_status';
import CustomNotificationsModal from '~/notifications/components/custom_notifications_modal.vue';
import { i18n } from '~/notifications/constants';

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
};

const mockToastShow = jest.fn();

describe('CustomNotificationsModal', () => {
  let wrapper;
  let mockAxios;

  function createComponent(options = {}) {
    const { injectedProperties = {}, props = {} } = options;
    return extendedWrapper(
      shallowMount(CustomNotificationsModal, {
        props: {
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
          GlFormGroup,
          GlFormCheckbox,
        },
      }),
    );
  }

  const findModalBodyDescription = () => wrapper.find(GlSprintf);
  const findAllCheckboxes = () => wrapper.findAll(GlFormCheckbox);
  const findCheckboxAt = (index) => findAllCheckboxes().at(index);

  beforeEach(() => {
    gon.api_version = 'v4';
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.restore();
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the body title and the body message', () => {
      expect(wrapper.findByTestId('modalBodyTitle').text()).toBe(
        i18n.customNotificationsModal.bodyTitle,
      );
      expect(findModalBodyDescription().attributes('message')).toContain(
        i18n.customNotificationsModal.bodyMessage,
      );
    });

    describe('checkbox items', () => {
      beforeEach(async () => {
        wrapper = createComponent();

        wrapper.setData({
          events: [
            { id: 'new_release', enabled: true, name: 'New release', loading: false },
            { id: 'new_note', enabled: false, name: 'New note', loading: true },
          ],
        });

        await wrapper.vm.$nextTick();
      });

      it.each`
        index | eventId          | eventName        | enabled  | loading
        ${0}  | ${'new_release'} | ${'New release'} | ${true}  | ${false}
        ${1}  | ${'new_note'}    | ${'New note'}    | ${false} | ${true}
      `(
        'renders a checkbox for "$eventName" with checked=$enabled',
        async ({ index, eventName, enabled, loading }) => {
          const checkbox = findCheckboxAt(index);
          expect(checkbox.text()).toContain(eventName);
          expect(checkbox.vm.$attrs.checked).toBe(enabled);
          expect(checkbox.find(GlLoadingIcon).exists()).toBe(loading);
        },
      );
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
            .reply(httpStatus.OK, mockNotificationSettingsResponses.default);

          wrapper = createComponent({ injectedProperties });

          wrapper.find(GlModal).vm.$emit('show');

          await waitForPromises();

          expect(axios.get).toHaveBeenCalledWith(endpointUrl);
        },
      );

      it('updates the loading state and the events property', async () => {
        const endpointUrl = '/api/v4/notification_settings';

        mockAxios
          .onGet(endpointUrl)
          .reply(httpStatus.OK, mockNotificationSettingsResponses.default);

        wrapper = createComponent();

        wrapper.find(GlModal).vm.$emit('show');
        expect(wrapper.vm.isLoading).toBe(true);

        await waitForPromises();

        expect(axios.get).toHaveBeenCalledWith(endpointUrl);
        expect(wrapper.vm.isLoading).toBe(false);
        expect(wrapper.vm.events).toEqual([
          { id: 'new_release', enabled: true, name: 'New release', loading: false },
          { id: 'new_note', enabled: false, name: 'New note', loading: false },
        ]);
      });

      it('shows a toast message when the request fails', async () => {
        mockAxios.onGet('/api/v4/notification_settings').reply(httpStatus.NOT_FOUND, {});
        wrapper = createComponent();

        wrapper.find(GlModal).vm.$emit('show');

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
        'updates the $notificationType notification settings when $condition and the user clicks the checkbox ',
        async ({ projectId, groupId, endpointUrl }) => {
          mockAxios
            .onGet(endpointUrl)
            .reply(httpStatus.OK, mockNotificationSettingsResponses.default);

          mockAxios
            .onPut(endpointUrl)
            .reply(httpStatus.OK, mockNotificationSettingsResponses.updated);

          const injectedProperties = {
            projectId,
            groupId,
          };

          wrapper = createComponent({ injectedProperties });

          wrapper.setData({
            events: [
              { id: 'new_release', enabled: true, name: 'New release', loading: false },
              { id: 'new_note', enabled: false, name: 'New note', loading: false },
            ],
          });

          await wrapper.vm.$nextTick();

          findCheckboxAt(1).vm.$emit('change', true);

          await waitForPromises();

          expect(axios.put).toHaveBeenCalledWith(endpointUrl, {
            new_note: true,
          });

          expect(wrapper.vm.events).toEqual([
            { id: 'new_release', enabled: true, name: 'New release', loading: false },
            { id: 'new_note', enabled: true, name: 'New note', loading: false },
          ]);
        },
      );

      it('shows a toast message when the request fails', async () => {
        mockAxios.onPut('/api/v4/notification_settings').reply(httpStatus.NOT_FOUND, {});
        wrapper = createComponent();

        wrapper.setData({
          events: [
            { id: 'new_release', enabled: true, name: 'New release', loading: false },
            { id: 'new_note', enabled: false, name: 'New note', loading: false },
          ],
        });

        await wrapper.vm.$nextTick();

        findCheckboxAt(1).vm.$emit('change', true);

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          'An error occurred while updating the notification settings. Please try again.',
        );
      });
    });
  });
});
