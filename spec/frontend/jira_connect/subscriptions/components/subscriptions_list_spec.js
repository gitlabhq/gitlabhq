import { GlButton, GlEmptyState, GlTable } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';

import * as JiraConnectApi from '~/jira_connect/subscriptions/api';
import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import { reloadPage } from '~/jira_connect/subscriptions/utils';
import { mockSubscription } from '../mock_data';

jest.mock('~/jira_connect/subscriptions/utils');

describe('SubscriptionsList', () => {
  let wrapper;
  let store;

  const createComponent = ({ mountFn = shallowMount, provide = {} } = {}) => {
    store = createStore();

    wrapper = mountFn(SubscriptionsList, {
      provide,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlTable = () => wrapper.findComponent(GlTable);
  const findUnlinkButton = () => findGlTable().findComponent(GlButton);
  const clickUnlinkButton = () => findUnlinkButton().trigger('click');

  describe('template', () => {
    it('renders GlEmptyState when subscriptions is empty', () => {
      createComponent();

      expect(findGlEmptyState().exists()).toBe(true);
      expect(findGlTable().exists()).toBe(false);
    });

    it('renders GlTable when subscriptions are present', () => {
      createComponent({
        provide: {
          subscriptions: [mockSubscription],
        },
      });

      expect(findGlEmptyState().exists()).toBe(false);
      expect(findGlTable().exists()).toBe(true);
    });
  });

  describe('on "Unlink" button click', () => {
    let removeSubscriptionSpy;

    beforeEach(() => {
      createComponent({
        mountFn: mount,
        provide: {
          subscriptions: [mockSubscription],
        },
      });
      removeSubscriptionSpy = jest.spyOn(JiraConnectApi, 'removeSubscription').mockResolvedValue();
    });

    it('sets button to loading and sends request', async () => {
      expect(findUnlinkButton().props('loading')).toBe(false);

      clickUnlinkButton();

      await wrapper.vm.$nextTick();

      expect(findUnlinkButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(removeSubscriptionSpy).toHaveBeenCalledWith(mockSubscription.unlink_path);
    });

    describe('when request is successful', () => {
      it('reloads the page', async () => {
        clickUnlinkButton();

        await waitForPromises();

        expect(reloadPage).toHaveBeenCalled();
      });
    });

    describe('when request has errors', () => {
      const mockErrorMessage = 'error message';
      const mockError = { response: { data: { error: mockErrorMessage } } };

      beforeEach(() => {
        jest.spyOn(JiraConnectApi, 'removeSubscription').mockRejectedValue(mockError);
        jest.spyOn(store, 'commit');
      });

      it('sets alert', async () => {
        clickUnlinkButton();

        await waitForPromises();

        expect(reloadPage).not.toHaveBeenCalled();
        expect(store.commit.mock.calls).toEqual(
          expect.arrayContaining([
            [
              SET_ALERT,
              {
                message: mockErrorMessage,
                variant: 'danger',
              },
            ],
          ]),
        );
      });
    });
  });
});
