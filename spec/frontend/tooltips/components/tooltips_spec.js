import { GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockMutationObserver } from 'helpers/mock_dom_observer';
import Tooltips from '~/tooltips/components/tooltips.vue';

describe('tooltips/components/tooltips.vue', () => {
  const { trigger: triggerMutate } = useMockMutationObserver();
  let wrapper;

  const buildWrapper = () => {
    wrapper = shallowMount(Tooltips);
  };

  const createTooltipTarget = (attributes = {}) => {
    const target = document.createElement('button');
    const defaults = {
      title: 'default title',
      ...attributes,
    };

    Object.keys(defaults).forEach((name) => {
      target.setAttribute(name, defaults[name]);
    });

    document.body.appendChild(target);

    return target;
  };

  const allTooltips = () => wrapper.findAllComponents(GlTooltip);

  describe('addTooltips', () => {
    let target;

    beforeEach(() => {
      buildWrapper();

      target = createTooltipTarget();
    });

    it('attaches tooltips to the targets specified', async () => {
      wrapper.vm.addTooltips([target]);

      await nextTick();

      expect(wrapper.findComponent(GlTooltip).props('target')).toBe(target);
    });

    it('does not attach a tooltip to a target with empty title', async () => {
      target.setAttribute('title', '');

      wrapper.vm.addTooltips([target]);

      await nextTick();

      expect(wrapper.findComponent(GlTooltip).exists()).toBe(false);
    });

    it('does not attach a tooltip twice to the same element', async () => {
      wrapper.vm.addTooltips([target]);
      wrapper.vm.addTooltips([target]);

      await nextTick();

      expect(wrapper.findAllComponents(GlTooltip)).toHaveLength(1);
    });

    it('sets tooltip content from title attribute', async () => {
      wrapper.vm.addTooltips([target]);

      await nextTick();

      expect(wrapper.findComponent(GlTooltip).text()).toBe(target.getAttribute('title'));
    });

    it('supports HTML content', async () => {
      target = createTooltipTarget({
        title: 'content with <b>HTML</b>',
        'data-html': true,
      });
      wrapper.vm.addTooltips([target]);

      await nextTick();

      expect(wrapper.findComponent(GlTooltip).html()).toContain(target.getAttribute('title'));
    });

    it('sets the configuration values passed in the config object', async () => {
      const config = { show: true };
      target = createTooltipTarget();
      wrapper.vm.addTooltips([target], config);
      await nextTick();
      expect(wrapper.findComponent(GlTooltip).props()).toMatchObject(config);
    });

    it.each`
      attribute           | value                 | prop
      ${'data-placement'} | ${'bottom'}           | ${'placement'}
      ${'data-container'} | ${'custom-container'} | ${'container'}
      ${'data-boundary'}  | ${'viewport'}         | ${'boundary'}
      ${'data-triggers'}  | ${'manual'}           | ${'triggers'}
    `(
      'sets $prop to $value when $attribute is set in target',
      async ({ attribute, value, prop }) => {
        target = createTooltipTarget({ [attribute]: value });
        wrapper.vm.addTooltips([target]);

        await nextTick();

        expect(wrapper.findComponent(GlTooltip).props(prop)).toBe(value);
      },
    );
  });

  describe('dispose', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('removes all tooltips when elements is nil', async () => {
      wrapper.vm.addTooltips([createTooltipTarget(), createTooltipTarget()]);
      await nextTick();

      wrapper.vm.dispose();
      await nextTick();

      expect(allTooltips()).toHaveLength(0);
    });

    it('removes the tooltips that target the elements specified', async () => {
      const target = createTooltipTarget();

      wrapper.vm.addTooltips([target, createTooltipTarget()]);
      await nextTick();

      wrapper.vm.dispose(target);
      await nextTick();

      expect(allTooltips()).toHaveLength(1);
    });
  });

  describe('observe', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('removes tooltip when target is removed from the document', async () => {
      const target = createTooltipTarget();

      wrapper.vm.addTooltips([target, createTooltipTarget()]);
      await nextTick();

      triggerMutate(document.body, {
        entry: { removedNodes: [target] },
        options: { childList: true },
      });
      await nextTick();

      expect(allTooltips()).toHaveLength(1);
    });
  });

  describe('triggerEvent', () => {
    it('triggers a bootstrap-vue tooltip global event for the tooltip specified', async () => {
      const target = createTooltipTarget();
      const event = 'hide';

      buildWrapper();

      wrapper.vm.addTooltips([target]);

      await nextTick();

      wrapper.vm.triggerEvent(target, event);

      expect(wrapper.findComponent(GlTooltip).emitted(event)).toHaveLength(1);
    });
  });

  describe('fixTitle', () => {
    it('updates tooltip content with the latest value the target title property', async () => {
      const target = createTooltipTarget();
      const currentTitle = 'title';
      const newTitle = 'new title';

      target.setAttribute('title', currentTitle);

      buildWrapper();

      wrapper.vm.addTooltips([target]);

      await nextTick();

      expect(wrapper.findComponent(GlTooltip).text()).toBe(currentTitle);

      target.setAttribute('title', newTitle);
      wrapper.vm.fixTitle(target);

      await nextTick();

      expect(wrapper.findComponent(GlTooltip).text()).toBe(newTitle);
    });
  });

  it('disconnects mutation observer on beforeDestroy', () => {
    buildWrapper();
    wrapper.vm.addTooltips([createTooltipTarget()]);
    const { observer } = wrapper.vm;
    jest.spyOn(observer, 'disconnect');

    expect(observer.disconnect).toHaveBeenCalledTimes(0);

    wrapper.destroy();

    expect(observer.disconnect).toHaveBeenCalledTimes(1);
  });

  it('exposes hidden event', async () => {
    buildWrapper();
    wrapper.vm.addTooltips([createTooltipTarget()]);

    await nextTick();

    wrapper.findComponent(GlTooltip).vm.$emit('hidden');
    expect(wrapper.emitted('hidden')).toHaveLength(1);
  });
});
