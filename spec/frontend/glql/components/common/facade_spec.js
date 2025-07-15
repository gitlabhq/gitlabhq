import { GlAlert, GlButton, GlSkeletonLoader, GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { stubCrypto } from 'helpers/crypto';
import GlqlFacade from '~/glql/components/common/facade.vue';
import GlqlActions from '~/glql/components/common/actions.vue';
import { executeAndPresentQuery, presentPreview } from '~/glql/core';
import Counter from '~/glql/utils/counter';
import { eventHubByKey } from '~/glql/utils/event_hub_factory';
import { MOCK_ISSUES } from '../../mock_data';

jest.mock('~/glql/core');

describe('GlqlFacade', () => {
  let wrapper;
  const mockQueryKey = 'glql_key';
  const mockEventHub = eventHubByKey(mockQueryKey);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();
  const createComponent = async (props = {}, glFeatures = {}) => {
    wrapper = mountExtended(GlqlFacade, {
      propsData: {
        query: 'assignee = "foo"',
        ...props,
      },
      provide: {
        glFeatures,
        queryKey: mockQueryKey,
      },
    });
    await nextTick();
    await waitForPromises();
  };

  const triggerIntersectionObserver = async () => {
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');
    await nextTick();
    await waitForPromises();
  };

  beforeEach(stubCrypto);

  describe('when glqlLoadOnClick feature flag is enabled', () => {
    beforeEach(async () => {
      await createComponent({}, { glqlLoadOnClick: true });
    });

    it('renders the query in a code block', () => {
      expect(wrapper.find('code').text()).toBe('assignee = "foo"');
    });

    it('renders the Load GLQL view button', () => {
      expect(wrapper.findComponent(GlButton).text()).toEqual('Load GLQL view');
    });
  });

  it('shows skeleton loader when loading', async () => {
    presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
    executeAndPresentQuery.mockImplementation(() => new Promise(() => {})); // Never resolves
    await createComponent();
    await triggerIntersectionObserver();

    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('when the query is successful', () => {
    const MockComponent = { render: (h) => h('div') };

    beforeEach(async () => {
      presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
      executeAndPresentQuery.mockResolvedValue({
        component: MockComponent,
        data: { count: 2, ...MOCK_ISSUES },
      });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('renders presenter component after successful query execution', () => {
      expect(wrapper.findComponent(MockComponent).exists()).toBe(true);
    });

    it('renders actions', () => {
      expect(wrapper.findComponent(GlqlActions).props()).toEqual({
        modalTitle: 'GLQL list',
        showCopyContents: true,
      });
    });

    it('renders a footer text', () => {
      expect(wrapper.text()).toContain('View powered by GLQL');
    });

    it('shows a "No data" message if the list of items provided is empty', async () => {
      presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
      executeAndPresentQuery.mockResolvedValue({
        component: MockComponent,
        data: { count: 0, nodes: [] },
      });
      await createComponent();
      await triggerIntersectionObserver();

      expect(wrapper.text()).toContain('No data found for this query');
    });

    it('tracks GLQL render event', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'render_glql_block',
        { label: 'glql_key' },
        undefined,
      );
    });

    it('reloads the query when reload event is emitted on event hub', async () => {
      jest.spyOn(wrapper.vm, 'reloadGlqlBlock');

      mockEventHub.$emit('reload');

      await nextTick();

      expect(wrapper.vm.reloadGlqlBlock).toHaveBeenCalled();
    });
  });

  describe('when the query results in a timeout (503) error', () => {
    beforeEach(async () => {
      presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
      executeAndPresentQuery.mockRejectedValue({ networkError: { statusCode: 503 } });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays timeout error alert', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('warning');
      expect(alert.text()).toContain(
        'GLQL view timed out. Add more filters to reduce the number of results.',
      );
      expect(alert.props('primaryButtonText')).toBe('Retry');
    });

    it('retries query execution when primary action of timeout error alert is triggered', async () => {
      presentPreview.mockClear();
      executeAndPresentQuery.mockClear();
      executeAndPresentQuery.mockResolvedValue({ component: { render: (h) => h('div') } });

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();

      expect(executeAndPresentQuery).toHaveBeenCalledWith('assignee = "foo"', 'glql_key');
    });
  });

  describe('when the query results in a forbidden (403) error', () => {
    beforeEach(async () => {
      presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
      executeAndPresentQuery.mockRejectedValue({ networkError: { statusCode: 403 } });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays forbidden error alert', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toContain('GLQL view timed out. Try again later.');
    });
  });

  describe('when the query results in a syntax error', () => {
    beforeEach(async () => {
      presentPreview.mockRejectedValue(new Error('Syntax error: Unexpected `=`'));
      executeAndPresentQuery.mockRejectedValue(new Error('Syntax error: Unexpected `=`'));

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays error alert on query failure, formatted by marked', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('warning');
      expect(alert.find('ul li').html()).toMatchInlineSnapshot(`
<li>
  Syntax error: Unexpected
  <code>
    =
  </code>
</li>
`);
    });

    it('dismisses alert when dismiss event is emitted', async () => {
      let alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);

      alert.vm.$emit('dismiss');
      await nextTick();

      alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(false);
    });
  });

  describe('when number of GLQL blocks on page exceeds the limit', () => {
    beforeEach(async () => {
      presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
      executeAndPresentQuery.mockResolvedValue({ render: (h) => h('div') });

      // Simulate exceeding the limit
      jest.spyOn(Counter.prototype, 'increment').mockImplementation(() => {
        throw new Error('Counter exceeded max value');
      });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays limit error alert after exceeding GLQL block limit', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('warning');
      expect(alert.text()).toContain(
        'Only 20 GLQL views can be automatically displayed on a page. Click the button below to manually display this block.',
      );
      expect(alert.props('primaryButtonText')).toBe('Display block');
    });

    it('retries query execution when primary action of limit error alert is triggered', async () => {
      presentPreview.mockClear();
      presentPreview.mockResolvedValue({ component: { render: (h) => h(GlSkeletonLoader) } });
      executeAndPresentQuery.mockClear();
      executeAndPresentQuery.mockResolvedValue({ component: { render: (h) => h('div') } });

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();

      expect(executeAndPresentQuery).toHaveBeenCalledWith('assignee = "foo"', 'glql_key');
    });
  });
});
