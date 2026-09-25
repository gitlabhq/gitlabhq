import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlTab, GlTabs } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';
import MergeRequestsWidgetList from '~/homepage/components/merge_requests_widget_list.vue';
import BaseWidget from '~/homepage/components/base_widget.vue';
import mergeRequestsWidgetQuery from '~/homepage/graphql/queries/merge_requests_widget.query.graphql';
import {
  mergeRequestsResponse,
  emptyMergeRequestsResponse,
  manyMergeRequestsResponse,
} from './mocks/merge_requests_widget_query_mocks';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('MergeRequestsWidget', () => {
  let wrapper;

  // The default stub renders only the default slot, so the tab label and count, which
  // live in the #title slot, would never render.
  const GlTabStub = stubComponent(GlTab, {
    template: '<li><slot name="title" /><slot /></li>',
  });

  const findTabsNav = () => wrapper.findComponent(GlTabs);
  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findLists = () => wrapper.findAllComponents(MergeRequestsWidgetList);
  const findAssignedList = () =>
    wrapper.findComponentByTestId('assigned-list', MergeRequestsWidgetList);
  const findError = () => wrapper.findByTestId('error-message');
  const findLoadingState = () => wrapper.findByTestId('loading-state');
  const findSkeletons = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findTabCounts = () => wrapper.findAllByTestId('tab-count');

  const createComponent = ({
    handler = jest.fn().mockResolvedValue(mergeRequestsResponse),
  } = {}) => {
    wrapper = shallowMountExtended(MergeRequestsWidget, {
      apolloProvider: createMockApollo([[mergeRequestsWidgetQuery, handler]]),
      stubs: { GlTab: GlTabStub },
    });

    return handler;
  };

  describe('while loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the widget heading', () => {
      expect(wrapper.find('h2').text()).toBe('Merge requests');
    });

    it('renders a skeleton loader per row', () => {
      expect(findLoadingState().exists()).toBe(true);
      expect(findSkeletons()).toHaveLength(4);
    });

    it('does not render the tab', () => {
      expect(findTabs()).toHaveLength(0);
    });
  });

  describe('when the query succeeds', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('stops rendering the loading state', () => {
      expect(findLoadingState().exists()).toBe(false);
    });

    it('renders the assigned tab', () => {
      expect(findTabs()).toHaveLength(1);
    });

    // The card is narrow, and the two labels plus their count badges overflow it at
    // small widths. The nav scrolls horizontally instead of wrapping onto two lines,
    // matching how the merge request page tabs behave.
    // The two labels plus their count badges overflow the narrow card, so the nav
    // scrolls horizontally, the way the merge request page tabs do. Every class is
    // load-bearing: gl-whitespace-nowrap stops the label itself breaking onto a
    // second line (.gl-tab-nav-item sets no white-space of its own), and that is
    // what pushes the content past the nav so overflow-x-auto has something to
    // scroll. gl-min-w-0 lets the nav shrink, since .gl-tabs-nav is a gl-grow item.
    it('scrolls the tab bar horizontally rather than wrapping', () => {
      expect(findTabsNav().props('navClass')).toBe(
        'gl-flex-nowrap gl-whitespace-nowrap gl-overflow-x-auto gl-min-w-0 gl-px-2',
      );
    });

    it('renders the tab title', () => {
      expect(wrapper.text()).toContain('Assigned to you');
    });

    it('renders the total count on the tab', () => {
      expect(findTabCounts().at(0).text()).toBe('2');
    });

    // The count is hidden by page_bundles/personal_homepage.scss once the card is too
    // narrow for the labels plus counts; the screen reader text stays either way.
    it('marks the counts so they can be hidden on a narrow card', () => {
      expect(findTabCounts().at(0).classes()).toContain('homepage-merge-requests-widget-tab-count');
    });

    it('renders a list for the tab', () => {
      expect(findLists()).toHaveLength(1);
    });

    it('passes the assigned merge requests to the first list', () => {
      expect(findAssignedList().props('mergeRequests')).toHaveLength(2);
      expect(findAssignedList().props('trackingProperty')).toBe('Assigned to you');
    });

    it('does not render an error', () => {
      expect(findError().exists()).toBe(false);
    });
  });

  describe('when there are no merge requests', () => {
    beforeEach(async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(emptyMergeRequestsResponse) });
      await waitForPromises();
    });

    it('still renders the tab with a zero count', () => {
      expect(findTabs()).toHaveLength(1);
      expect(findTabCounts().at(0).text()).toBe('0');
    });

    it('passes the assigned empty text down', () => {
      expect(findAssignedList().props('emptyText')).toBe('No merge requests assigned to you.');
    });
  });

  describe('when the user has more merge requests than the widget can show', () => {
    beforeEach(async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(manyMergeRequestsResponse) });
      await waitForPromises();
    });

    it('shows the real total on the tab badge, not the number of rows fetched', () => {
      expect(findTabCounts().at(0).text()).toBe('9');
    });

    it('never renders more than the 8 rows the query fetches', () => {
      expect(findAssignedList().props('mergeRequests')).toHaveLength(8);
    });
  });

  describe('when the query fails', () => {
    const error = new Error('nope');

    beforeEach(async () => {
      createComponent({ handler: jest.fn().mockRejectedValue(error) });
      await waitForPromises();
    });

    it('renders the error message', () => {
      expect(findError().text()).toBe(
        'Could not load your merge requests. Refresh the page to try again.',
      );
    });

    it('does not render the tab', () => {
      expect(findTabs()).toHaveLength(0);
    });

    it('does not render the loading state', () => {
      expect(findLoadingState().exists()).toBe(false);
    });

    it('reports the error to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('refresh functionality', () => {
    it('refetches the merge requests on becoming visible again', async () => {
      const handler = createComponent();
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(1);

      wrapper.findComponent(BaseWidget).vm.$emit('visible');
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(2);
    });

    // vue-apollo tracks its own loading state per smart query, so `loading` flips
    // on refetch without notifyOnNetworkStatusChange. The skeleton therefore shows
    // again while refreshing, matching every other homepage widget.
    it('shows the skeleton again while refreshing', async () => {
      createComponent();
      await waitForPromises();

      expect(findLoadingState().exists()).toBe(false);

      wrapper.findComponent(BaseWidget).vm.$emit('visible');
      await nextTick();

      expect(findLoadingState().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingState().exists()).toBe(false);
      expect(findTabs()).toHaveLength(1);
    });
  });
});
