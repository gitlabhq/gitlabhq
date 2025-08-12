import { GlAlert, GlButton, GlSkeletonLoader, GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { stubCrypto } from 'helpers/crypto';
import GlqlFacade from '~/glql/components/common/facade.vue';
import GlqlActions from '~/glql/components/common/actions.vue';
import { parse } from '~/glql/core/parser';
import { execute } from '~/glql/core/executor';
import { transform } from '~/glql/core/transformer';
import DataPresenter from '~/glql/components/presenters/data.vue';
import Counter from '~/glql/utils/counter';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { MOCK_ISSUES, MOCK_FIELDS } from '../../mock_data';

jest.mock('~/glql/core/parser', () => ({
  parse: jest.fn(),
}));

jest.mock('~/glql/core/transformer', () => ({
  transform: jest.fn(),
}));

jest.mock('~/glql/core/executor', () => ({
  execute: jest.fn(),
}));

describe('GlqlFacade', () => {
  let wrapper;
  const mockQueryKey = 'glql_key';

  const { bindInternalEventDocument } = useMockInternalEventsTracking();
  const createComponent = async (props = {}, glFeatures = {}) => {
    wrapper = mountExtended(GlqlFacade, {
      propsData: {
        queryKey: mockQueryKey,
        queryYaml: 'assignee = "foo"',
        ...props,
      },
      provide: {
        glFeatures,
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

    it('renders the Load embedded view button', () => {
      expect(wrapper.findComponent(GlButton).text()).toEqual('Load embedded view');
    });
  });

  it('shows skeleton loader when loading', async () => {
    parse.mockResolvedValue({ query: 'query {}', config: { display: 'list' }, variables: {} });
    transform.mockResolvedValue({ fields: MOCK_FIELDS });
    execute.mockImplementation(() => new Promise(() => {})); // Never resolves

    await createComponent();
    await triggerIntersectionObserver();

    expect(wrapper.findComponent(DataPresenter).props('loading')).toBe(true);
    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('when the query is successful', () => {
    beforeEach(async () => {
      parse.mockResolvedValue({
        query: 'query {}',
        config: { display: 'list', title: 'Some title', description: 'Some description' },
        variables: {},
      });
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });
      transform.mockResolvedValue({ fields: MOCK_FIELDS, data: { count: 2, ...MOCK_ISSUES } });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('renders crud component', () => {
      const crudComponent = wrapper.findComponent(CrudComponent);
      expect(crudComponent.props('anchorId')).toBe('glql-glql_key');
      expect(crudComponent.props('title')).toBe('Some title');
      expect(crudComponent.props('description')).toBe('Some description');
      expect(crudComponent.props('count')).toBe(2);
    });

    it('renders presenter component after successful query execution', () => {
      const presenter = wrapper.findComponent(DataPresenter);
      expect(presenter.exists()).toBe(true);
      expect(presenter.props('data')).toEqual({ count: 2, ...MOCK_ISSUES });
      expect(presenter.props('fields')).toEqual(MOCK_FIELDS);
      expect(presenter.props('displayType')).toEqual('list');
      expect(presenter.props('loading')).toEqual(false);
    });

    it('renders actions', () => {
      expect(wrapper.findComponent(GlqlActions).props()).toEqual({
        modalTitle: 'Some title',
        showCopyContents: true,
      });
    });

    it('renders a footer text', () => {
      expect(wrapper.text()).toContain('Embedded view powered by GLQL');
    });

    it('shows a "No data" message if the list of items provided is empty', async () => {
      execute.mockResolvedValue({ count: 0, nodes: [] });
      transform.mockResolvedValue({ fields: MOCK_FIELDS, data: { count: 0, nodes: [] } });

      await createComponent();
      await triggerIntersectionObserver();

      expect(wrapper.text()).toContain('No data found for this query');
    });

    it('tracks GLQL render event', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'render_glql_block',
        { label: expect.any(String) },
        undefined,
      );
    });

    it('reloads the query on reload event', async () => {
      jest.spyOn(wrapper.vm, 'reloadGlqlBlock');

      wrapper.findComponent(GlqlActions).vm.$emit('reload');

      await nextTick();

      expect(wrapper.vm.reloadGlqlBlock).toHaveBeenCalled();
    });
  });

  describe('when the query results in a timeout (503) error', () => {
    beforeEach(async () => {
      execute.mockRejectedValue({ networkError: { statusCode: 503 } });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays timeout error alert', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('warning');
      expect(alert.text()).toContain(
        'Embedded view timed out. Add more filters to reduce the number of results.',
      );
      expect(alert.props('primaryButtonText')).toBe('Retry');
    });

    it('retries query execution when primary action of timeout error alert is triggered', async () => {
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });
      transform.mockResolvedValue({ fields: MOCK_FIELDS, data: { count: 2, ...MOCK_ISSUES } });

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();
      await waitForPromises();

      expect(execute).toHaveBeenCalled();
    });
  });

  describe('when the query results in a forbidden (403) error', () => {
    beforeEach(async () => {
      execute.mockRejectedValue({ networkError: { statusCode: 403 } });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays forbidden error alert', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toContain('Embedded view timed out. Try again later.');
    });
  });

  describe('when the query results in a syntax error', () => {
    beforeEach(async () => {
      parse.mockRejectedValue(new Error('Syntax error: Unexpected `=`'));

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
      parse.mockResolvedValue({
        query: 'query {}',
        config: { display: 'list', title: 'Some title', description: 'Some description' },
        variables: {},
      });
      transform.mockResolvedValue({ fields: MOCK_FIELDS, data: { count: 2, ...MOCK_ISSUES } });
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });

      // Simulate exceeding the limit
      jest.spyOn(Counter.prototype, 'increment').mockImplementation(() => {
        throw new Error('Counter exceeded max value');
      });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('displays limit error alert after exceeding embedded view block limit', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('warning');
      expect(alert.text()).toContain(
        'Only 20 embedded views can be automatically displayed on a page. Click the button below to manually display this view.',
      );
      expect(alert.props('primaryButtonText')).toBe('Display view');
    });

    it('retries query execution when primary action of limit error alert is triggered', async () => {
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });
      transform.mockResolvedValue({ fields: MOCK_FIELDS, data: { count: 2, ...MOCK_ISSUES } });

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();
      await waitForPromises();

      expect(execute).toHaveBeenCalled();
    });
  });
});
