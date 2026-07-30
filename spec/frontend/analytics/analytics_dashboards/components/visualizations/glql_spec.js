import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlqlVisualization from '~/analytics/analytics_dashboards/components/visualizations/glql.vue';
import GlqlResolver from '~/glql/components/common/resolver.vue';
import GlqlViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyGLQLNodeAsGFM } from '~/glql/utils/copy_as_gfm';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

jest.mock('~/glql/utils/copy_as_gfm', () => ({
  copyGLQLNodeAsGFM: jest.fn(),
}));
jest.mock('~/lib/utils/copy_to_clipboard');

describe('GlqlVisualization', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(GlqlVisualization, {
      propsData: props,
    });
  };

  const findResolver = () => wrapper.findComponent(GlqlResolver);
  const findModal = () => wrapper.findComponent(GlqlViewSourceModal);
  const findEmptyState = () => wrapper.findByText('No results match your query or filter.');
  const lastActions = () => wrapper.emitted('set-actions').at(-1)[0];
  const findAction = (text) => lastActions().find((action) => action.text === text);

  it('renders the GLQL resolver', () => {
    const glqlQuery = 'type = Issue AND state = opened';

    createWrapper({ data: glqlQuery });

    expect(findResolver().exists()).toBe(true);
    expect(findResolver().props()).toEqual({
      glqlQuery,
      trackingEventName: 'render_analytics_dashboard_glql_panel',
    });
  });

  describe('error handling', () => {
    beforeEach(() => {
      createWrapper({ data: 'type = Issue AND state = opened' });
    });

    it('forwards a resolver error to the panel via set-alerts', () => {
      const error = new Error('Something went wrong');

      findResolver().vm.$emit('change', { error });

      expect(wrapper.emitted('set-alerts')).toEqual([
        [
          {
            errors: [error],
            title: 'An error occurred when trying to display this panel',
            description: 'Something went wrong',
            canRetry: false,
          },
        ],
      ]);
    });

    it('does not emit set-alerts when the resolver reports no error', () => {
      findResolver().vm.$emit('change', { error: undefined });

      expect(wrapper.emitted('set-alerts')).toBeUndefined();
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

    it('resets the resolver data when the query changes', async () => {
      findResolver().vm.$emit('change', { data: { nodes: [] } });
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);

      wrapper.setProps({ data: 'type = Issue AND state = closed' });
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findResolver().exists()).toBe(true);
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

    it('copies the rendered contents when "Copy contents" is triggered', async () => {
      findResolver().vm.$emit('change', { data: { count: 1, nodes: [{ id: 1 }] } });
      await nextTick();

      findAction('Copy contents').action();

      expect(copyGLQLNodeAsGFM).toHaveBeenCalledWith(findResolver().element);
    });

    it('emits reload to reload the whole panel when "Reload" is triggered', () => {
      findAction('Reload').action();

      expect(wrapper.emitted('reload')).toEqual([[]]);
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
