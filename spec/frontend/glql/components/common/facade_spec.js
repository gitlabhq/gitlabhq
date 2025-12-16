import { GlAlert, GlButton, GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GlqlFacade from '~/glql/components/common/facade.vue';
import GlqlActions from '~/glql/components/common/actions.vue';
import GlqlResolver from '~/glql/components/common/resolver.vue';
import Counter from '~/glql/utils/counter';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { MOCK_ISSUES, MOCK_FIELDS } from '../../mock_data';

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

  const createComponent = async (props = {}, glFeatures = {}) => {
    wrapper = mountExtended(GlqlFacade, {
      propsData: {
        queryKey: 'glql_key',
        queryYaml: 'assignee = "foo"',
        ...props,
      },
      provide: {
        glFeatures,
      },
      stubs: {
        GlqlResolver: true,
      },
    });
    await nextTick();
  };

  const findResolver = () => wrapper.findComponent(GlqlResolver);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);

  const triggerIntersectionObserver = async () => {
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');
    await nextTick();
  };

  const emitResolverChange = async (data = {}) => {
    findResolver().vm.$emit('change', {
      loading: false,
      query: MOCK_PARSE_OUTPUT.query,
      config: MOCK_PARSE_OUTPUT.config,
      data: { count: 2, ...MOCK_ISSUES },
      aggregate: MOCK_PARSE_OUTPUT.aggregate,
      groupBy: MOCK_PARSE_OUTPUT.groupBy,
      error: null,
      ...data,
    });
    await nextTick();
  };

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

  describe('title', () => {
    beforeEach(async () => {
      await createComponent();
      await triggerIntersectionObserver();
    });

    it('shows skeleton loader when loading', async () => {
      await emitResolverChange({ loading: true, config: {} });

      expect(findCrudComponent().props('title')).toBe('');
      expect(wrapper.findByTestId('title-skeleton-loader').exists()).toBe(true);
    });

    it('shows a title set by the config', async () => {
      const title = 'facade';
      await emitResolverChange({ config: { title } });

      expect(findCrudComponent().props('title')).toBe(title);
    });

    it('shows a default title for table views', async () => {
      await emitResolverChange({ config: { display: 'table' } });

      expect(findCrudComponent().props('title')).toBe('Embedded table view');
    });

    it('shows a default title', async () => {
      await emitResolverChange({ config: {} });

      expect(findCrudComponent().props('title')).toBe('Embedded list view');
    });
  });

  describe('when the query includes a collapsed flag', () => {
    beforeEach(async () => {
      await createComponent({
        queryYaml: 'query: assignee = "foo"\n collapsed: true',
      });
      await triggerIntersectionObserver();
      await emitResolverChange({
        config: { ...MOCK_PARSE_OUTPUT.config, collapsed: true },
      });
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
      await createComponent();
      await triggerIntersectionObserver();
      await emitResolverChange();
    });

    it('renders crud component in expanded state', () => {
      const crudComponent = wrapper.findComponent(CrudComponent);
      expect(crudComponent.props('anchorId')).toBe('glql-glql_key');
      expect(crudComponent.props('title')).toBe('Some title');
      expect(crudComponent.props('description')).toBe('Some description');
      expect(crudComponent.props('count')).toBe(2);

      expect(crudComponent.props('collapsed')).toBe(false);
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
      await createComponent();
      await triggerIntersectionObserver();
      await emitResolverChange({ data: { count: 0, nodes: [] } });

      expect(wrapper.text()).toContain('No data found for this query');
    });

    it('reloads the query on reload event', async () => {
      const oldResolver = findResolver();

      wrapper.findComponent(GlqlActions).vm.$emit('reload');
      await nextTick();

      expect(oldResolver.exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });
  });

  describe('when the query results in a timeout (503) error', () => {
    beforeEach(async () => {
      await createComponent();
      await triggerIntersectionObserver();
      await emitResolverChange({ error: { networkError: { statusCode: 503 } } });
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

    it('creates a new resolver to retry the query when primary action of timeout error alert is triggered', async () => {
      const oldResolver = findResolver();

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();

      expect(oldResolver.exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });
  });

  describe('when the query results in a forbidden (403) error', () => {
    beforeEach(async () => {
      await createComponent();
      await triggerIntersectionObserver();
      await emitResolverChange({ error: { networkError: { statusCode: 403 } } });
    });

    it('displays forbidden error alert', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toContain('You do not have permission to view this embedded view.');
    });
  });

  describe('when the query results in a syntax error', () => {
    beforeEach(async () => {
      await createComponent();
      await triggerIntersectionObserver();
      await emitResolverChange({ error: new Error('Syntax error: Unexpected `=`') });
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
  });

  describe('when number of GLQL blocks on page exceeds the limit', () => {
    beforeEach(async () => {
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

    it('creates a new resolver to retry the query when primary action of limit error alert is triggered', async () => {
      const oldResolver = findResolver();

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();

      expect(oldResolver.exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });
  });

  describe('when the query is aggregated', () => {
    beforeEach(async () => {
      await createComponent();
      await triggerIntersectionObserver();
      await emitResolverChange({ groupBy: [{}], aggregate: [{}] });
    });

    it('does not show the count on the crudComponent', () => {
      const crudComponent = wrapper.findComponent(CrudComponent);

      expect(crudComponent.props('count')).toBe(null);
    });
  });
});
