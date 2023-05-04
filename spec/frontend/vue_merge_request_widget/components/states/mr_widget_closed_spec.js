import { nextTick } from 'vue';
import { shallowMount, mount } from '@vue/test-utils';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';

import api from '~/api';

import showGlobalToast from '~/vue_shared/plugins/global_toast';

import closedComponent from '~/vue_merge_request_widget/components/states/mr_widget_closed.vue';
import MrWidgetAuthorTime from '~/vue_merge_request_widget/components/mr_widget_author_time.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import Actions from '~/vue_merge_request_widget/components/action_buttons.vue';

import { MR_WIDGET_CLOSED_REOPEN_FAILURE } from '~/vue_merge_request_widget/i18n';

jest.mock('~/api', () => ({
  updateMergeRequest: jest.fn(),
}));
jest.mock('~/vue_shared/plugins/global_toast');

useMockLocationHelper();

const MOCK_DATA = {
  iid: 1,
  metrics: {
    mergedBy: {},
    closedBy: {
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://localhost:3000/root',
      avatarUrl: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    },
    mergedAt: 'Jan 24, 2018 1:02pm UTC',
    closedAt: 'Jan 24, 2018 1:02pm UTC',
    readableMergedAt: '',
    readableClosedAt: 'less than a minute ago',
  },
  targetBranchPath: '/twitter/flight/commits/so_long_jquery',
  targetBranch: 'so_long_jquery',
  targetProjectId: 'twitter/flight',
};

function createComponent({ shallow = true, props = {} } = {}) {
  const mounter = shallow ? shallowMount : mount;

  return mounter(closedComponent, {
    propsData: {
      mr: MOCK_DATA,
      ...props,
    },
  });
}

function findActions(wrapper) {
  return wrapper.findComponent(StateContainer).findComponent(Actions);
}

function findReopenActionButton(wrapper) {
  return findActions(wrapper).find('button[data-testid="extension-actions-reopen-button"]');
}

describe('MRWidgetClosed', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders closed icon', () => {
    expect(wrapper.findComponent(StateContainer).exists()).toBe(true);
    expect(wrapper.findComponent(StateContainer).props().status).toBe('closed');
  });

  it('renders mr widget author time', () => {
    expect(wrapper.findComponent(MrWidgetAuthorTime).exists()).toBe(true);
    expect(wrapper.findComponent(MrWidgetAuthorTime).props()).toEqual({
      actionText: 'Closed by',
      author: MOCK_DATA.metrics.closedBy,
      dateTitle: MOCK_DATA.metrics.closedAt,
      dateReadable: MOCK_DATA.metrics.readableClosedAt,
    });
  });

  describe('actions', () => {
    describe('reopen', () => {
      beforeEach(() => {
        window.gon = { current_user_id: 1 };
        api.updateMergeRequest.mockResolvedValue(true);
        wrapper = createComponent({ shallow: false });
      });

      it('shows the "reopen" button', () => {
        expect(wrapper.findComponent(StateContainer).props().actions.length).toBe(1);
        expect(findReopenActionButton(wrapper).text()).toBe('Reopen');
      });

      it('does not show widget actions when the user is not logged in', () => {
        window.gon = {};

        wrapper = createComponent();

        expect(findActions(wrapper).exists()).toBe(false);
      });

      it('makes the reopen request with the correct MR information', async () => {
        const reopenButton = findReopenActionButton(wrapper);

        reopenButton.trigger('click');
        await nextTick();

        expect(api.updateMergeRequest).toHaveBeenCalledWith(
          MOCK_DATA.targetProjectId,
          MOCK_DATA.iid,
          { state_event: 'reopen' },
        );
      });

      it('shows "Reopening..." while the reopen network request is pending', async () => {
        const reopenButton = findReopenActionButton(wrapper);

        api.updateMergeRequest.mockReturnValue(new Promise(() => {}));

        reopenButton.trigger('click');
        await nextTick();

        expect(reopenButton.text()).toBe('Reopening...');
      });

      it('shows "Refreshing..." when the reopen has succeeded', async () => {
        const reopenButton = findReopenActionButton(wrapper);

        reopenButton.trigger('click');
        await waitForPromises();

        expect(reopenButton.text()).toBe('Refreshing...');
      });

      it('reloads the page when a reopen has succeeded', async () => {
        const reopenButton = findReopenActionButton(wrapper);

        reopenButton.trigger('click');
        await waitForPromises();

        expect(window.location.reload).toHaveBeenCalledTimes(1);
      });

      it('shows "Reopen" when a reopen request has failed', async () => {
        const reopenButton = findReopenActionButton(wrapper);

        api.updateMergeRequest.mockRejectedValue(false);

        reopenButton.trigger('click');
        await waitForPromises();

        expect(window.location.reload).not.toHaveBeenCalled();
        expect(reopenButton.text()).toBe('Reopen');
      });

      it('requests a toast popup when a reopen request has failed', async () => {
        const reopenButton = findReopenActionButton(wrapper);

        api.updateMergeRequest.mockRejectedValue(false);

        reopenButton.trigger('click');
        await waitForPromises();

        expect(showGlobalToast).toHaveBeenCalledTimes(1);
        expect(showGlobalToast).toHaveBeenCalledWith(MR_WIDGET_CLOSED_REOPEN_FAILURE);
      });
    });
  });
});
