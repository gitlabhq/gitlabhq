import { GlToggle, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BoardSidebarSubscription from '~/boards/components/sidebar/board_sidebar_subscription.vue';
import { createStore } from '~/boards/stores';
import * as types from '~/boards/stores/mutation_types';
import { mockActiveIssue } from '../../mock_data';

Vue.use(Vuex);

describe('~/boards/components/sidebar/board_sidebar_subscription_spec.vue', () => {
  let wrapper;
  let store;

  const findNotificationHeader = () => wrapper.find("[data-testid='notification-header-text']");
  const findToggle = () => wrapper.find(GlToggle);
  const findGlLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const createComponent = (activeBoardItem = { ...mockActiveIssue }) => {
    store = createStore();
    store.state.boardItems = { [activeBoardItem.id]: activeBoardItem };
    store.state.activeId = activeBoardItem.id;

    wrapper = mount(BoardSidebarSubscription, {
      store,
      provide: {
        emailsDisabled: false,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
    jest.clearAllMocks();
  });

  describe('Board sidebar subscription component template', () => {
    it('displays "notifications" heading', () => {
      createComponent();

      expect(findNotificationHeader().text()).toBe('Notifications');
    });

    it('renders toggle with label', () => {
      createComponent();

      expect(findToggle().props('label')).toBe(BoardSidebarSubscription.i18n.header.title);
    });

    it('renders toggle as "off" when currently not subscribed', () => {
      createComponent();

      expect(findToggle().exists()).toBe(true);
      expect(findToggle().props('value')).toBe(false);
    });

    it('renders toggle as "on" when currently subscribed', () => {
      createComponent({
        ...mockActiveIssue,
        subscribed: true,
      });

      expect(findToggle().exists()).toBe(true);
      expect(findToggle().props('value')).toBe(true);
    });

    describe('when notification emails have been disabled', () => {
      beforeEach(() => {
        createComponent({
          ...mockActiveIssue,
          emailsDisabled: true,
        });
      });

      it('displays a message that notification have been disabled', () => {
        expect(findNotificationHeader().text()).toBe(
          'Notifications have been disabled by the project or group owner',
        );
      });

      it('does not render the toggle button', () => {
        expect(findToggle().exists()).toBe(false);
      });
    });
  });

  describe('Board sidebar subscription component `behavior`', () => {
    const mockSetActiveIssueSubscribed = (subscribedState) => {
      jest.spyOn(wrapper.vm, 'setActiveItemSubscribed').mockImplementation(async () => {
        store.commit(types.UPDATE_BOARD_ITEM_BY_ID, {
          itemId: mockActiveIssue.id,
          prop: 'subscribed',
          value: subscribedState,
        });
      });
    };

    it('subscribing to notification', async () => {
      createComponent();
      mockSetActiveIssueSubscribed(true);

      expect(findGlLoadingIcon().exists()).toBe(false);

      findToggle().trigger('click');

      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(true);
      expect(wrapper.vm.setActiveItemSubscribed).toHaveBeenCalledWith({
        subscribed: true,
        projectPath: 'gitlab-org/test-subgroup/gitlab-test',
      });

      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(findToggle().props('value')).toBe(true);
    });

    it('unsubscribing from notification', async () => {
      createComponent({
        ...mockActiveIssue,
        subscribed: true,
      });
      mockSetActiveIssueSubscribed(false);

      expect(findGlLoadingIcon().exists()).toBe(false);

      findToggle().trigger('click');

      await wrapper.vm.$nextTick();

      expect(wrapper.vm.setActiveItemSubscribed).toHaveBeenCalledWith({
        subscribed: false,
        projectPath: 'gitlab-org/test-subgroup/gitlab-test',
      });
      expect(findGlLoadingIcon().exists()).toBe(true);

      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(findToggle().props('value')).toBe(false);
    });

    it('flashes an error message when setting the subscribed state fails', async () => {
      createComponent();
      jest.spyOn(wrapper.vm, 'setActiveItemSubscribed').mockImplementation(async () => {
        throw new Error();
      });
      jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});

      findToggle().trigger('click');

      await wrapper.vm.$nextTick();
      expect(wrapper.vm.setError).toHaveBeenCalled();
      expect(wrapper.vm.setError.mock.calls[0][0].message).toBe(
        wrapper.vm.$options.i18n.updateSubscribedErrorMessage,
      );
    });
  });
});
