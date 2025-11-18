import { GlAlert, GlButton, GlSkeletonLoader, GlIntersectionObserver } from '@gitlab/ui';
import { identity } from 'lodash';
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

jest.mock('~/glql/core/parser');
jest.mock('~/glql/core/transformer');
jest.mock('~/glql/core/executor', () => ({
  execute: jest.fn(),
}));

const MOCK_PARSE_OUTPUT = {
  query: 'query {}',
  config: { display: 'list', title: 'Some title', description: 'Some description' },
  variables: {
    limit: { value: null, type: 'Int' },
    after: { value: null, type: 'String' },
    before: { value: null, type: 'String' },
  },
  fields: MOCK_FIELDS,
  aggregate: [],
  groupBy: [],
};

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

  beforeEach(() => {
    stubCrypto();
    parse.mockResolvedValue(MOCK_PARSE_OUTPUT);
    transform.mockImplementation(identity);
  });

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
    execute.mockImplementation(() => new Promise(() => {})); // Never resolves

    await createComponent();
    await triggerIntersectionObserver();

    expect(wrapper.findComponent(DataPresenter).props('loading')).toBe(true);
    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('when the query includes a collapsed flag', () => {
    beforeEach(async () => {
      parse.mockResolvedValue({
        ...MOCK_PARSE_OUTPUT,
        config: { ...MOCK_PARSE_OUTPUT.config, collapsed: true },
      });

      await createComponent({
        queryYaml: 'query: assignee = "foo"\n collapsed: true',
      });
      await triggerIntersectionObserver();
    });

    it('renders the crud component as collapsed', () => {
      expect(wrapper.findComponent(CrudComponent).props('collapsed')).toBe(true);
    });

    describe('when the crud component dispatches an expanded event', () => {
      beforeEach(() => {
        wrapper.findComponent(CrudComponent).vm.$emit('expanded');
      });

      it('sets crud component state to not collapsed', () => {
        expect(wrapper.findComponent(CrudComponent).props('collapsed')).toBe(false);
      });

      describe('and later a collapsed event', () => {
        beforeEach(() => {
          wrapper.findComponent(CrudComponent).vm.$emit('collapsed');
        });

        it('sets state to collapsed', () => {
          expect(wrapper.findComponent(CrudComponent).props('collapsed')).toBe(true);
        });
      });
    });
  });

  describe('when the query is successful', () => {
    beforeEach(async () => {
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('renders crud component in expanded state', () => {
      const crudComponent = wrapper.findComponent(CrudComponent);
      expect(crudComponent.props('anchorId')).toBe('glql-glql_key');
      expect(crudComponent.props('title')).toBe('Some title');
      expect(crudComponent.props('description')).toBe('Some description');
      expect(crudComponent.props('count')).toBe(2);

      expect(crudComponent.props('collapsed')).toBe(false);
    });

    it('renders presenter component after successful query execution', () => {
      const presenter = wrapper.findComponent(DataPresenter);
      expect(presenter.exists()).toBe(true);
      expect(presenter.props('data')).toEqual({ count: 2, ...MOCK_ISSUES });
      expect(presenter.props('fields')).toEqual(MOCK_FIELDS);
      expect(presenter.props('displayType')).toEqual('list');
      expect(presenter.props('loading')).toEqual(false);
      expect(presenter.props('aggregate')).toEqual(MOCK_PARSE_OUTPUT.aggregate);
      expect(presenter.props('groupBy')).toEqual(MOCK_PARSE_OUTPUT.groupBy);
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

  describe('when variables are missing', () => {
    beforeEach(async () => {
      parse.mockResolvedValue({ ...MOCK_PARSE_OUTPUT, variables: {} });
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('renders the presenter component successfully', () => {
      const presenter = wrapper.findComponent(DataPresenter);
      expect(presenter.exists()).toBe(true);
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

    it('shows the code block after dismissing the alert', async () => {
      const alert = wrapper.findComponent(GlAlert);

      alert.vm.$emit('dismiss');
      await nextTick();

      const codeBlock = wrapper.find('.markdown-code-block code');
      expect(codeBlock.exists()).toBe(true);
      expect(codeBlock.text()).toBe('assignee = "foo"');
    });
  });

  describe('when number of GLQL blocks on page exceeds the limit', () => {
    beforeEach(async () => {
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

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();
      await waitForPromises();

      expect(execute).toHaveBeenCalled();
    });
  });

  describe('when the query is aggregated', () => {
    beforeEach(async () => {
      parse.mockResolvedValue({ ...MOCK_PARSE_OUTPUT, groupBy: [{}], aggregate: [{}] });
      execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });

      await createComponent();
      await triggerIntersectionObserver();
    });

    it('does not show the count on the crudComponent', () => {
      const crudComponent = wrapper.findComponent(CrudComponent);

      expect(crudComponent.props('count')).toBe(null);
    });
  });

  it('presenter error', async () => {
    execute.mockResolvedValue({ count: 2, ...MOCK_ISSUES });
    await createComponent();
    await triggerIntersectionObserver();

    await wrapper.findComponent(DataPresenter).vm.$emit('error', 'presenter error');

    const alert = wrapper.findComponent(GlAlert);
    expect(alert.exists()).toBe(true);
    expect(alert.text()).toBe('presenter error');
  });
});
