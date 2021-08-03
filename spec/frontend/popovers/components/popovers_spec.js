import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useMockMutationObserver } from 'helpers/mock_dom_observer';
import Popovers from '~/popovers/components/popovers.vue';

describe('popovers/components/popovers.vue', () => {
  const { trigger: triggerMutate } = useMockMutationObserver();
  let wrapper;

  const buildWrapper = (...targets) => {
    wrapper = shallowMount(Popovers);
    wrapper.vm.addPopovers(targets);
    return wrapper.vm.$nextTick();
  };

  const createPopoverTarget = (options = {}) => {
    const target = document.createElement('button');
    const dataset = {
      title: 'default title',
      content: 'some content',
      ...options,
    };

    Object.entries(dataset).forEach(([key, value]) => {
      target.dataset[key] = value;
    });

    document.body.appendChild(target);

    return target;
  };

  const allPopovers = () => wrapper.findAll(GlPopover);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('addPopovers', () => {
    it('attaches popovers to the targets specified', async () => {
      const target = createPopoverTarget();
      await buildWrapper(target);
      expect(wrapper.find(GlPopover).props('target')).toBe(target);
    });

    it('does not attach a popover twice to the same element', async () => {
      const target = createPopoverTarget();
      buildWrapper(target);
      wrapper.vm.addPopovers([target]);

      await wrapper.vm.$nextTick();

      expect(wrapper.findAll(GlPopover)).toHaveLength(1);
    });

    it('supports HTML content', async () => {
      const content = 'content with <b>HTML</b>';
      await buildWrapper(
        createPopoverTarget({
          content,
          html: true,
        }),
      );
      const html = wrapper.find(GlPopover).html();

      expect(html).toContain(content);
    });

    it.each`
      option         | value
      ${'placement'} | ${'bottom'}
      ${'triggers'}  | ${'manual'}
    `('sets $option to $value when data-$option is set in target', async ({ option, value }) => {
      await buildWrapper(createPopoverTarget({ [option]: value }));

      expect(wrapper.find(GlPopover).props(option)).toBe(value);
    });
  });

  describe('dispose', () => {
    it('removes all popovers when elements is nil', async () => {
      await buildWrapper(createPopoverTarget(), createPopoverTarget());

      wrapper.vm.dispose();
      await wrapper.vm.$nextTick();

      expect(allPopovers()).toHaveLength(0);
    });

    it('removes the popovers that target the elements specified', async () => {
      const target = createPopoverTarget();

      await buildWrapper(target, createPopoverTarget());

      wrapper.vm.dispose(target);
      await wrapper.vm.$nextTick();

      expect(allPopovers()).toHaveLength(1);
    });
  });

  describe('observe', () => {
    it('removes popover when target is removed from the document', async () => {
      const target = createPopoverTarget();
      await buildWrapper(target);

      wrapper.vm.addPopovers([target, createPopoverTarget()]);
      await wrapper.vm.$nextTick();

      triggerMutate(document.body, {
        entry: { removedNodes: [target] },
        options: { childList: true },
      });
      await wrapper.vm.$nextTick();

      expect(allPopovers()).toHaveLength(1);
    });
  });

  it('disconnects mutation observer on beforeDestroy', async () => {
    await buildWrapper(createPopoverTarget());
    const { observer } = wrapper.vm;
    jest.spyOn(observer, 'disconnect');

    expect(observer.disconnect).toHaveBeenCalledTimes(0);

    wrapper.destroy();

    expect(observer.disconnect).toHaveBeenCalledTimes(1);
  });
});
