import { nextTick } from 'vue';
import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import GlqlVisualization from '~/analytics/analytics_dashboards/components/visualizations/glql.vue';
import PanelState from '~/analytics/shared/components/panel_state.vue';
import GlqlResolver from '~/glql/components/common/resolver.vue';
import GlqlViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyGLQLContents } from '~/glql/utils/copy_as_gfm';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/glql/utils/copy_as_gfm', () => ({
  copyGLQLContents: jest.fn(),
}));
jest.mock('~/lib/utils/copy_to_clipboard');

describe('GlqlVisualization', () => {
  let wrapper;

  const createWrapper = (props = {}, { glFeatures = {}, attachTo } = {}) => {
    wrapper = shallowMountExtended(GlqlVisualization, {
      propsData: props,
      provide: { glFeatures },
      attachTo,
    });
  };

  const findResolver = () => wrapper.findComponent(GlqlResolver);
  const findViewportObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findModal = () => wrapper.findComponent(GlqlViewSourceModal);
  const findPanelState = () => wrapper.findComponent(PanelState);
  const findEmptyState = () => {
    const state = findPanelState();
    return state.exists() && state.props('variant') === 'no-data' ? state : { exists: () => false };
  };
  const lastActions = () => wrapper.emitted('set-actions').at(-1)[0];
  const findAction = (text) => lastActions().find((action) => action.text === text);

  it('renders the GLQL resolver', () => {
    const glqlQuery = 'type = Issue AND state = opened';

    createWrapper({ data: glqlQuery });

    expect(findResolver().exists()).toBe(true);
    expect(findResolver().props()).toEqual({
      glqlQuery,
      comparison: null,
      trackingEventName: 'render_analytics_dashboard_glql_panel',
      scope: null,
      queue: 'glql-queue-dashboard',
      bindings: [],
    });
  });

  describe('when the deferOffscreenGlqlDashboardPanels feature flag is enabled', () => {
    beforeEach(() => {
      createWrapper(
        { data: 'type = Issue AND state = opened' },
        { glFeatures: { deferOffscreenGlqlDashboardPanels: true } },
      );
    });

    it('waits for the panel to near the viewport before mounting the resolver', () => {
      expect(findResolver().exists()).toBe(false);
      expect(findViewportObserver().props('options')).toEqual({
        root: null,
        rootMargin: '100% 0px',
      });
    });

    describe('when the dashboard scrolls inside a page panel', () => {
      let scrollPanel;

      beforeEach(() => {
        scrollPanel = document.createElement('div');
        scrollPanel.classList.add('js-static-panel-inner');
        const mountPoint = document.createElement('div');
        scrollPanel.appendChild(mountPoint);
        document.body.appendChild(scrollPanel);

        createWrapper(
          { data: 'type = Issue AND state = opened' },
          { glFeatures: { deferOffscreenGlqlDashboardPanels: true }, attachTo: mountPoint },
        );
      });

      afterEach(() => {
        scrollPanel.remove();
      });

      it('observes the panel against the page panel', () => {
        expect(findViewportObserver().props('options').root).toBe(scrollPanel);
      });
    });

    describe('when the panel nears the viewport', () => {
      beforeEach(async () => {
        findViewportObserver().vm.$emit('appear');
        await nextTick();
      });

      // The observer is removed with it, so leaving the viewport again never unmounts the resolver.
      it('mounts the resolver and stops observing', () => {
        expect(findResolver().exists()).toBe(true);
        expect(findViewportObserver().exists()).toBe(false);
      });

      it('waits for the viewport again when the query changes', async () => {
        wrapper.setProps({ data: 'type = Issue AND state = closed' });
        await nextTick();

        expect(findResolver().exists()).toBe(false);
        expect(findViewportObserver().exists()).toBe(true);
      });
    });
  });

  describe('when the deferOffscreenGlqlDashboardPanels feature flag is disabled', () => {
    beforeEach(() => {
      createWrapper({ data: 'type = Issue AND state = opened' });
    });

    it('mounts the resolver straight away', () => {
      expect(findResolver().exists()).toBe(true);
      expect(findViewportObserver().exists()).toBe(false);
    });
  });

  // The resolver does not re-query on prop changes, so the panel remounts it instead.
  describe('when the panel changes', () => {
    const query = 'type = Issue AND state = opened';

    it('remounts the resolver when the query changes', async () => {
      createWrapper({ data: query, namespace: 'gitlab-org' });
      const original = findResolver().vm;

      wrapper.setProps({ data: 'type = Issue AND state = closed' });
      await nextTick();

      expect(findResolver().vm).not.toBe(original);
    });

    it('remounts the resolver when the namespace changes', async () => {
      createWrapper({ data: query, namespace: 'gitlab-org' });
      const original = findResolver().vm;

      wrapper.setProps({ namespace: 'gitlab-com' });
      await nextTick();

      expect(findResolver().vm).not.toBe(original);
    });

    it('remounts the resolver when the scope filters change', async () => {
      createWrapper({ data: query, filters: { groups: ['gitlab-org'] } });
      const original = findResolver().vm;

      wrapper.setProps({ filters: { groups: ['gitlab-org', 'gitlab-com'] } });
      await nextTick();

      expect(findResolver().vm).not.toBe(original);
    });

    it('keeps the same resolver when nothing it depends on changes', async () => {
      createWrapper({ data: query, namespace: 'gitlab-org' });
      const original = findResolver().vm;

      wrapper.setProps({ options: { showActions: false } });
      await nextTick();

      expect(findResolver().vm).toBe(original);
    });
  });

  describe('comparison', () => {
    const comparisonQuery = 'type = Issue AND created >= "2026-01-01"';

    it("bundles the derived query and the panel's metric for the resolver", () => {
      createWrapper({
        data: 'type = Issue AND created >= "2026-02-01"',
        options: { comparisonQuery, trendMetric: 'totalCount' },
      });

      expect(findResolver().props('comparison')).toEqual({
        query: comparisonQuery,
        metric: 'totalCount',
      });
    });

    it('leaves the metric out when the panel selects a single metric', () => {
      createWrapper({
        data: 'type = Issue AND created >= "2026-02-01"',
        options: { comparisonQuery },
      });

      expect(findResolver().props('comparison')).toEqual({
        query: comparisonQuery,
        metric: undefined,
      });
    });

    // The data source only derives a query for a panel that asked for trends, so a metric
    // on its own is not a comparison.
    it('is null without a derived query', () => {
      createWrapper({
        data: 'type = Issue AND created >= "2026-02-01"',
        options: { trendMetric: 'totalCount' },
      });

      expect(findResolver().props('comparison')).toBe(null);
    });
  });

  describe('scope', () => {
    const glqlQuery = 'type = Issue AND state = opened';

    // Without a namespace the resolver falls back to deriving one from the URL, which is what
    // group and project dashboards already rely on.
    it('is null when no namespace is given', () => {
      createWrapper({ data: glqlQuery });

      expect(findResolver().props('scope')).toBe(null);
    });

    it('is null when the given namespace is empty', () => {
      createWrapper({ data: glqlQuery, namespace: '', isProject: false });

      expect(findResolver().props('scope')).toBe(null);
    });

    it('is a group scope for a group namespace', () => {
      createWrapper({ data: glqlQuery, namespace: 'gitlab-org', isProject: false });

      expect(findResolver().props('scope')).toEqual({ group: 'gitlab-org' });
    });

    it('is a project scope for a project namespace', () => {
      createWrapper({ data: glqlQuery, namespace: 'gitlab-org/gitlab', isProject: true });

      expect(findResolver().props('scope')).toEqual({ project: 'gitlab-org/gitlab' });
    });
  });

  describe('the scope bindings', () => {
    const glqlQuery = 'type = Issue AND state = opened';

    it('is empty when the dashboard filters name no scope', () => {
      createWrapper({ data: glqlQuery });

      expect(findResolver().props('bindings')).toEqual([]);
    });

    it('binds the selected groups onto the query', () => {
      createWrapper({ data: glqlQuery, filters: { groups: ['gitlab-org', 'gitlab-com'] } });

      expect(findResolver().props('bindings')).toEqual([
        {
          target: { kind: 'filter', field: 'group' },
          value: { kind: 'list', values: ['gitlab-org', 'gitlab-com'] },
        },
      ]);
    });

    it('binds groups and projects as separate filters', () => {
      createWrapper({
        data: glqlQuery,
        filters: { groups: ['gitlab-org'], projects: ['gitlab-com/www-gitlab-com'] },
      });

      expect(findResolver().props('bindings')).toEqual([
        {
          target: { kind: 'filter', field: 'group' },
          value: { kind: 'list', values: ['gitlab-org'] },
        },
        {
          target: { kind: 'filter', field: 'project' },
          value: { kind: 'list', values: ['gitlab-com/www-gitlab-com'] },
        },
      ]);
    });

    it('leaves out a filter the dashboard has nothing selected for', () => {
      createWrapper({ data: glqlQuery, filters: { groups: [], projects: ['gitlab-org/gitlab'] } });

      expect(findResolver().props('bindings')).toEqual([
        {
          target: { kind: 'filter', field: 'project' },
          value: { kind: 'list', values: ['gitlab-org/gitlab'] },
        },
      ]);
    });
  });

  describe('error handling', () => {
    const graphQLError = (extensions) => ({ graphQLErrors: [{ message: 'failed', extensions }] });

    beforeEach(() => {
      createWrapper({ data: 'type = Issue AND state = opened' });
    });

    it.each`
      failure                            | error                                                                                                                              | variant
      ${'a deterministic query error'}   | ${new Error('boom')}                                                                                                               | ${'error-no-retry'}
      ${'a generic error'}               | ${graphQLError({ code: 'SOMETHING_UNEXPECTED' })}                                                                                  | ${'error'}
      ${'an authorization error'}        | ${graphQLError({ code: 'AGGREGATION_NOT_AUTHORIZED' })}                                                                            | ${'no-access'}
      ${'a legacy authorization error'}  | ${{ message: "ordering by 'x' is not authorized" }}                                                                                | ${'no-access'}
      ${'Siphon being unavailable'}      | ${graphQLError({ code: 'SIPHON_REPLICATION_DISABLED' })}                                                                           | ${'unavailable'}
      ${'ClickHouse not configured'}     | ${graphQLError({ code: 'CLICKHOUSE_NOT_CONFIGURED' })}                                                                             | ${'not-configured'}
      ${'a query timeout (HTTP 503)'}    | ${{ networkError: { statusCode: 503 } }}                                                                                           | ${'error'}
      ${'being rate limited (HTTP 403)'} | ${{ networkError: { statusCode: 403, result: { errors: [{ message: 'Query temporarily blocked due to repeated timeouts.' }] } } }} | ${'error-no-retry'}
      ${'an authorization 403'}          | ${{ networkError: { statusCode: 403 } }}                                                                                           | ${'no-access'}
    `('renders the $variant panel state for $failure', async ({ error, variant }) => {
      findResolver().vm.$emit('change', { error });
      await nextTick();

      expect(findPanelState().props('variant')).toBe(variant);
      expect(findResolver().exists()).toBe(false);
    });

    it('renders the error state compact for a stat display', async () => {
      findResolver().vm.$emit('change', { error: new Error('boom'), config: { display: 'stat' } });
      await nextTick();

      expect(findPanelState().props('compact')).toBe(true);
    });

    // A parse failure produces no config; only the compiler may read the query text,
    // so the state falls back to the full-size layout.
    it('renders the full-size error state when parsing failed before a config existed', async () => {
      findResolver().vm.$emit('change', { error: new Error('parse error') });
      await nextTick();

      expect(findPanelState().props('compact')).toBe(false);
    });

    it('keeps loaded rows instead of an error state when a continuation page fails', async () => {
      findResolver().vm.$emit('change', {
        data: { count: 4, nodes: [{ id: 1 }, { id: 2 }] },
        error: new Error('page 2 failed'),
      });
      await nextTick();

      expect(findPanelState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('describes a timeout with actionable copy', async () => {
      findResolver().vm.$emit('change', { error: { networkError: { statusCode: 503 } } });
      await nextTick();

      expect(findPanelState().props('description')).toBe(
        'The query timed out. Select a shorter date range and try again.',
      );
    });

    it('captures generic errors in Sentry', async () => {
      const error = graphQLError({ code: 'SOMETHING_UNEXPECTED' });

      findResolver().vm.$emit('change', { error });
      await nextTick();

      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });

    // Parse, transform and presenter errors are query mistakes; only the author can fix them.
    it('does not capture deterministic query errors in Sentry', async () => {
      findResolver().vm.$emit('change', { error: new Error('Unknown field `foo`') });
      await nextTick();

      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('shows the query error message so the author can fix the query', async () => {
      findResolver().vm.$emit('change', { error: new Error('Unknown field `foo`') });
      await nextTick();

      expect(findPanelState().props('description')).toBe('Unknown field `foo`');
    });

    it('does not capture expected states in Sentry', async () => {
      findResolver().vm.$emit('change', {
        error: graphQLError({ code: 'AGGREGATION_NOT_AUTHORIZED' }),
      });
      await nextTick();

      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('renders no panel state when the resolver reports no error', () => {
      findResolver().vm.$emit('change', { error: undefined });

      expect(findPanelState().exists()).toBe(false);
    });

    it('re-runs the query with a fresh resolver on retry', async () => {
      findResolver().vm.$emit('change', { error: new Error('boom') });
      await nextTick();

      findPanelState().vm.$emit('retry');
      await nextTick();

      expect(findPanelState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('only emits the "Reload" action when the resolver reports an error', () => {
      findResolver().vm.$emit('change', { error: new Error('Something went wrong') });

      expect(lastActions().map((action) => action.text)).toEqual(['Reload']);
    });
  });

  describe('empty state', () => {
    beforeEach(() => {
      createWrapper({ data: 'type = Issue AND state = opened' });
    });

    it('does not render the empty state before the resolver reports data', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('renders the empty state when the resolver returns no nodes', async () => {
      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);
      expect(findResolver().exists()).toBe(false);
    });

    it('does not render the empty state when the resolver returns nodes', async () => {
      findResolver().vm.$emit('change', { data: { nodes: [{ id: 1 }] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('does not render the empty state when the resolver returns no data', async () => {
      findResolver().vm.$emit('change', { data: undefined });
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('renders the full empty state by default', async () => {
      findResolver().vm.$emit('change', { data: { nodes: [] }, config: { display: 'table' } });
      await nextTick();

      expect(findPanelState().props('compact')).toBe(false);
    });

    it('renders the compact empty state for a stat display', async () => {
      findResolver().vm.$emit('change', { data: { nodes: [] }, config: { display: 'stat' } });
      await nextTick();

      expect(findPanelState().props('compact')).toBe(true);
    });

    it('passes the empty state copy configured on the panel', async () => {
      createWrapper({
        data: 'type = Issue AND state = opened',
        options: {
          emptyState: { title: 'No data in this range', description: 'Use Duo to see data here.' },
        },
      });

      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findPanelState().props()).toMatchObject({
        title: 'No data in this range',
        description: 'Use Duo to see data here.',
      });
    });

    it('resets the resolver data when the query changes', async () => {
      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);

      wrapper.setProps({ data: 'type = Issue AND state = closed' });
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    // The empty state unmounts the resolver, so without this reset the resolver could never run
    // its own scope watcher and the panel would stay empty for the newly selected namespace.
    it('resets the resolver data when the namespace changes', async () => {
      createWrapper({ data: 'type = Issue AND state = opened', namespace: 'gitlab-org' });

      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);

      wrapper.setProps({ namespace: 'gitlab-com' });
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('resets the resolver data when the scope filters change', async () => {
      createWrapper({
        data: 'type = Issue AND state = opened',
        filters: { groups: ['gitlab-org'] },
      });

      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);

      wrapper.setProps({ filters: { groups: ['gitlab-com'] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
    });

    it('keeps the resolver data when only the date range changes', async () => {
      createWrapper({
        data: 'type = Issue AND state = opened',
        filters: { groups: ['gitlab-org'], dateRangeOption: '7d' },
      });

      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);

      wrapper.setProps({ filters: { groups: ['gitlab-org'], dateRangeOption: '30d' } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('panel actions', () => {
    const glqlQuery = 'type = Issue AND state = opened';
    const wrappedQuery = `\`\`\`glql\n${glqlQuery}\n\`\`\``;

    beforeEach(async () => {
      createWrapper({ data: glqlQuery });

      // The resolver reports its state on load, which is when the panel actions
      // are emitted.
      findResolver().vm.$emit('change', { data: undefined });
      await nextTick();
    });

    it('emits the base set of actions when the resolver reports its state', () => {
      expect(lastActions().map((action) => action.text)).toEqual([
        'View source',
        'Copy source',
        'Reload',
      ]);
    });

    it('adds "Copy contents" once the resolver returns results', async () => {
      findResolver().vm.$emit('change', { data: { count: 2, nodes: [{ id: 1 }, { id: 2 }] } });
      await nextTick();

      expect(lastActions().map((action) => action.text)).toEqual([
        'View source',
        'Copy source',
        'Copy contents',
        'Reload',
      ]);
    });

    it('copies the wrapped query when "Copy source" is triggered', () => {
      findAction('Copy source').action();

      expect(copyToClipboard).toHaveBeenCalledWith(wrappedQuery, document.body);
    });

    // Panels route through the same helper the embedded facade uses, so a chart panel copies a
    // table built from its data rather than the axis labels scraped out of its SVG.
    it('copies the contents with the state the resolver last reported', async () => {
      const change = {
        config: { display: 'columnChart' },
        data: { count: 1, nodes: [{ language: 'ruby', totalCount: 21 }] },
        fields: [
          { key: 'language', label: 'Language', type: 'dimension' },
          { key: 'totalCount', label: 'Total count', type: 'metric' },
        ],
      };

      findResolver().vm.$emit('change', change);
      await nextTick();

      findAction('Copy contents').action();

      expect(copyGLQLContents).toHaveBeenCalledWith({ ...change, el: findResolver().element });
    });

    it('emits reload to reload the whole panel when "Reload" is triggered', () => {
      findAction('Reload').action();

      expect(wrapper.emitted('reload')).toEqual([[]]);
    });

    // The panel re-fetch yields the same query string, so only a remount re-runs the query.
    it('remounts the resolver when "Reload" is triggered', async () => {
      const original = findResolver().vm;

      findAction('Reload').action();
      await nextTick();

      expect(findResolver().vm).not.toBe(original);
    });

    describe('when the panel opts out with showActions: false', () => {
      const createOptedOutWrapper = async (change) => {
        createWrapper({ data: glqlQuery, options: { showActions: false } });

        findResolver().vm.$emit('change', change);
        await nextTick();
      };

      it('emits no actions once the resolver returns results', async () => {
        await createOptedOutWrapper({ data: { count: 2, nodes: [{ id: 1 }, { id: 2 }] } });

        expect(lastActions()).toEqual([]);
      });

      // Otherwise the dropdown a panel asked to hide would reappear the moment it broke.
      it('emits no actions when the resolver reports an error', async () => {
        await createOptedOutWrapper({ error: new Error('Something went wrong') });

        expect(lastActions()).toEqual([]);
      });

      // The kebab's Reload is gone, so the inline state has to stand in for it.
      it('renders the inline error state', async () => {
        await createOptedOutWrapper({ error: new Error('Something went wrong') });

        expect(findPanelState().props('variant')).toBe('error-no-retry');
      });
    });

    it('emits the base set of actions when the panel opts in with showActions: true', async () => {
      createWrapper({ data: glqlQuery, options: { showActions: true } });

      findResolver().vm.$emit('change', { data: undefined });
      await nextTick();

      expect(lastActions().map((action) => action.text)).toEqual([
        'View source',
        'Copy source',
        'Reload',
      ]);
    });
  });

  describe('source modal', () => {
    const glqlQuery = 'type = Issue AND state = opened';

    beforeEach(async () => {
      createWrapper({ data: glqlQuery });

      // The resolver reports its state on load, which is when the panel actions
      // (including "View source") are emitted.
      findResolver().vm.$emit('change', { data: undefined });
      await nextTick();
    });

    it('is closed by default', () => {
      expect(findModal().props('visible')).toBe(false);
    });

    it('passes the query and title to the modal', () => {
      expect(findModal().props()).toMatchObject({
        query: glqlQuery,
        title: 'Panel query',
      });
    });

    it('opens when the "View source" action is triggered', async () => {
      findAction('View source').action();
      await nextTick();

      expect(findModal().props('visible')).toBe(true);
    });

    it('closes when the modal reports it has been dismissed', async () => {
      findAction('View source').action();
      await nextTick();

      findModal().vm.$emit('change', false);
      await nextTick();

      expect(findModal().props('visible')).toBe(false);
    });
  });
});
