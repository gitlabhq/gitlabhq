import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GlqlFacade from '~/glql/components/common/facade.vue';
import { executeAndPresentQuery } from '~/glql/core';
import Counter from '~/glql/utils/counter';

jest.mock('~/glql/core');

describe('GlqlFacade', () => {
  let wrapper;
  const createComponent = (props = {}) => {
    wrapper = mountExtended(GlqlFacade, {
      propsData: {
        query: 'assignee = "foo"',
        ...props,
      },
    });
  };

  it('renders the query in a code block', () => {
    createComponent();
    expect(wrapper.find('code').text()).toBe('assignee = "foo"');
  });

  it('shows loading icon when loading', async () => {
    executeAndPresentQuery.mockImplementation(() => new Promise(() => {})); // Never resolves
    createComponent();
    await nextTick();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('emits loading and loaded events', async () => {
    executeAndPresentQuery.mockResolvedValue({ render: (h) => h('div') });
    createComponent();
    await waitForPromises();

    expect(wrapper.emitted()).toHaveProperty('loading');
    expect(wrapper.emitted()).toHaveProperty('loaded');
  });

  it('renders presenter component after successful query execution', async () => {
    const MockComponent = { render: (h) => h('div') };
    executeAndPresentQuery.mockResolvedValue(MockComponent);
    createComponent();
    await waitForPromises();

    expect(wrapper.findComponent(MockComponent).exists()).toBe(true);
  });

  describe('when the query results in an error', () => {
    beforeEach(async () => {
      executeAndPresentQuery.mockRejectedValue(new Error('Syntax error: Unexpected `=`'));
      createComponent();
      await waitForPromises();
    });

    it('displays error alert on query failure, formatted by marked', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
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
    beforeEach(() => {
      executeAndPresentQuery.mockResolvedValue({ render: (h) => h('div') });

      // Simulate exceeding the limit
      jest.spyOn(Counter.prototype, 'increment').mockImplementation(() => {
        throw new Error('Counter exceeded max value');
      });

      createComponent();
      return nextTick();
    });
    it('displays limit error alert after exceeding GLQL block limit', () => {
      const alert = wrapper.findComponent(GlAlert);
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(
        'Only 20 GLQL blocks can be automatically displayed on a page. Click the button below to manually display this block.',
      );
      expect(alert.props('primaryButtonText')).toBe('Display block');
    });

    it('retries query execution when primary action of limit error alert is triggered', async () => {
      executeAndPresentQuery.mockClear();
      executeAndPresentQuery.mockResolvedValue({ render: (h) => h('div') });

      const alert = wrapper.findComponent(GlAlert);
      alert.vm.$emit('primaryAction');
      await nextTick();

      expect(executeAndPresentQuery).toHaveBeenCalledWith('assignee = "foo"');
    });
  });
});
