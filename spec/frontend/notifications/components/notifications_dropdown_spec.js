import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import { GlButtonGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import httpStatus from '~/lib/utils/http_status';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import NotificationsDropdownItem from '~/notifications/components/notifications_dropdown_item.vue';

const mockDropdownItems = ['global', 'watch', 'participating', 'mention', 'disabled'];
const mockToastShow = jest.fn();

describe('NotificationsDropdown', () => {
  let wrapper;
  let mockAxios;

  function createComponent(injectedProperties = {}) {
    return shallowMount(NotificationsDropdown, {
      stubs: {
        GlButtonGroup,
        GlDropdown,
        GlDropdownItem,
        NotificationsDropdownItem,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
      provide: {
        ...injectedProperties,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  }

  const findButtonGroup = () => wrapper.find(GlButtonGroup);
  const findDropdown = () => wrapper.find(GlDropdown);
  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findAllNotificationsDropdownItems = () => wrapper.findAll(NotificationsDropdownItem);
  const findDropdownItemAt = (index) =>
    findAllNotificationsDropdownItems().at(index).find(GlDropdownItem);

  const clickDropdownItemAt = async (index) => {
    const dropdownItem = findDropdownItemAt(index);
    dropdownItem.vm.$emit('click');

    await waitForPromises();
  };

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
    describe('when notification level is "custom"', () => {
      beforeEach(() => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: 'custom',
        });
      });

      it('renders a button group', () => {
        expect(findButtonGroup().exists()).toBe(true);
      });
    });

    describe('when notification level is not "custom"', () => {
      beforeEach(() => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: 'global',
        });
      });

      it('does not render a button group', () => {
        expect(findButtonGroup().exists()).toBe(false);
      });
    });

    describe('button tooltip', () => {
      const tooltipTitlePrefix = 'Notification setting';
      it.each`
        level              | title
        ${'global'}        | ${'Global'}
        ${'watch'}         | ${'Watch'}
        ${'participating'} | ${'Participate'}
        ${'mention'}       | ${'On mention'}
        ${'disabled'}      | ${'Disabled'}
        ${'custom'}        | ${'Custom'}
      `(`renders "${tooltipTitlePrefix} - $title" for "$level" level`, ({ level, title }) => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: level,
        });

        const tooltipElement = findByTestId('notificationButton');
        const tooltip = getBinding(tooltipElement.element, 'gl-tooltip');

        expect(tooltip.value.title).toBe(`${tooltipTitlePrefix} - ${title}`);
      });
    });

    describe('button icon', () => {
      beforeEach(() => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: 'disabled',
        });
      });

      it('renders the "notifications-off" icon when notification level is "disabled"', () => {
        expect(findDropdown().props('icon')).toBe('notifications-off');
      });

      it('renders the "notifications" icon when notification level is not "disabled"', () => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: 'global',
        });

        expect(findDropdown().props('icon')).toBe('notifications');
      });
    });

    describe('dropdown items', () => {
      it.each`
        dropdownIndex | level              | title            | description
        ${0}          | ${'global'}        | ${'Global'}      | ${'Use your global notification setting'}
        ${1}          | ${'watch'}         | ${'Watch'}       | ${'You will receive notifications for any activity'}
        ${2}          | ${'participating'} | ${'Participate'} | ${'You will only receive notifications for threads you have participated in'}
        ${3}          | ${'mention'}       | ${'On mention'}  | ${'You will receive notifications only for comments in which you were @mentioned'}
        ${4}          | ${'disabled'}      | ${'Disabled'}    | ${'You will not get any notifications via email'}
        ${5}          | ${'custom'}        | ${'Custom'}      | ${'You will only receive notifications for the events you choose'}
      `('displays "$title" and "$description"', ({ dropdownIndex, title, description }) => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: 'global',
        });

        expect(findAllNotificationsDropdownItems().at(dropdownIndex).props('title')).toBe(title);
        expect(findAllNotificationsDropdownItems().at(dropdownIndex).props('description')).toBe(
          description,
        );
      });
    });
  });

  describe('when selecting an item', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'put');
    });

    it.each`
      projectId | groupId | endpointUrl                                   | endpointType               | condition
      ${1}      | ${null} | ${'/api/v4/projects/1/notification_settings'} | ${'project notifications'} | ${'a projectId is given'}
      ${null}   | ${1}    | ${'/api/v4/groups/1/notification_settings'}   | ${'group notifications'}   | ${'a groupId is given'}
      ${null}   | ${null} | ${'/api/v4/notification_settings'}            | ${'global notifications'}  | ${'when neither projectId nor groupId are given'}
    `(
      'calls the $endpointType endpoint when $condition',
      async ({ projectId, groupId, endpointUrl }) => {
        wrapper = createComponent({
          dropdownItems: mockDropdownItems,
          initialNotificationLevel: 'global',
          projectId,
          groupId,
        });

        await clickDropdownItemAt(1);

        expect(axios.put).toHaveBeenCalledWith(endpointUrl, {
          level: 'watch',
        });
      },
    );

    it('updates the selectedNotificationLevel and marks the item with a checkmark', async () => {
      mockAxios.onPut('/api/v4/notification_settings').reply(httpStatus.OK, {});
      wrapper = createComponent({
        dropdownItems: mockDropdownItems,
        initialNotificationLevel: 'global',
      });

      const dropdownItem = findDropdownItemAt(1);

      await clickDropdownItemAt(1);

      expect(wrapper.vm.selectedNotificationLevel).toBe('watch');
      expect(dropdownItem.props('isChecked')).toBe(true);
    });

    it("won't update the selectedNotificationLevel and shows a toast message when the request fails and ", async () => {
      mockAxios.onPut('/api/v4/notification_settings').reply(httpStatus.NOT_FOUND, {});
      wrapper = createComponent({
        dropdownItems: mockDropdownItems,
        initialNotificationLevel: 'global',
      });

      await clickDropdownItemAt(1);

      expect(wrapper.vm.selectedNotificationLevel).toBe('global');
      expect(
        mockToastShow,
      ).toHaveBeenCalledWith(
        'An error occured while updating the notification settings. Please try again.',
        { type: 'error' },
      );
    });
  });
});
