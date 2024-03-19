import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockMutationObserver } from 'helpers/mock_dom_observer';
import Popovers from '~/popovers/components/popovers.vue';

describe('popovers/components/popovers.vue', () => {
  const { trigger: triggerMutate } = useMockMutationObserver();
  let wrapper;

  const buildWrapper = async (...targets) => {
    wrapper = shallowMount(Popovers);
    wrapper.vm.addPopovers(targets);
    await nextTick();
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

  const allPopovers = () => wrapper.findAllComponents(GlPopover);

  describe('addPopovers', () => {
    it('attaches popovers to the targets specified', async () => {
      const target = createPopoverTarget();
      await buildWrapper(target);
      expect(wrapper.findComponent(GlPopover).props('target')).toBe(target);
    });

    it('does not attach a popover twice to the same element', async () => {
      const target = createPopoverTarget();
      buildWrapper(target);
      wrapper.vm.addPopovers([target]);

      await nextTick();

      expect(wrapper.findAllComponents(GlPopover)).toHaveLength(1);
    });

    describe('title', () => {
      it('does not render an empty header when there is no title', async () => {
        const target = createPopoverTarget({ title: '' });
        await buildWrapper(target);
        expect(wrapper.find('.popover-header').exists()).toBe(false);
      });
    });

    describe('supports HTML content', () => {
      const svgIcon = '<svg><use xlink:href="icons.svg#test"></use></svg>';
      const escapedSvgIcon = '<svg><use xlink:href=&quot;icons.svg#test&quot;></use></svg>';

      it.each`
        description                         | content                          | render
        ${'renders html content correctly'} | ${'<b>HTML</b>'}                 | ${'<b>HTML</b>'}
        ${'removes any unsafe content'}     | ${'<script>alert(XSS)</script>'} | ${''}
        ${'renders svg icons correctly'}    | ${svgIcon}                       | ${escapedSvgIcon}
      `('$description', async ({ content, render }) => {
        await buildWrapper(createPopoverTarget({ content, html: true }));

        const html = wrapper.findComponent(GlPopover).html();
        expect(html).toContain(render);
      });
    });

    it.each`
      option         | value
      ${'placement'} | ${'bottom'}
      ${'triggers'}  | ${'manual'}
    `('sets $option to $value when data-$option is set in target', async ({ option, value }) => {
      await buildWrapper(createPopoverTarget({ [option]: value }));

      expect(wrapper.findComponent(GlPopover).props(option)).toBe(value);
    });
  });

  describe('dispose', () => {
    it('removes all popovers when elements is nil', async () => {
      await buildWrapper(createPopoverTarget(), createPopoverTarget());

      wrapper.vm.dispose();
      await nextTick();

      expect(allPopovers()).toHaveLength(0);
    });

    it('removes the popovers that target the elements specified', async () => {
      const target = createPopoverTarget();

      await buildWrapper(target, createPopoverTarget());

      wrapper.vm.dispose(target);
      await nextTick();

      expect(allPopovers()).toHaveLength(1);
    });
  });

  describe('observe', () => {
    it('removes popover when target is removed from the document', async () => {
      const target = createPopoverTarget();
      await buildWrapper(target);

      wrapper.vm.addPopovers([target, createPopoverTarget()]);
      await nextTick();

      triggerMutate(document.body, {
        entry: { removedNodes: [target] },
        options: { childList: true },
      });
      await nextTick();

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
