import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlqlVisualization from '~/analytics/analytics_dashboards/components/visualizations/glql.vue';
import GlqlResolver from '~/glql/components/common/resolver.vue';

describe('GlqlVisualization', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(GlqlVisualization, {
      propsData: props,
    });
  };

  const findResolver = () => wrapper.findComponent(GlqlResolver);
  const findEmptyState = () => wrapper.findByText('No results match your query or filter.');

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
});
