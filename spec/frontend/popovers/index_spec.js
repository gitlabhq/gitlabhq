import { nextTick } from 'vue';
import { initPopovers, dispose, destroy } from '~/popovers';

describe('popovers/index.js', () => {
  const createPopoverTarget = (trigger = 'hover') => {
    const target = document.createElement('button');
    const dataset = {
      title: 'default title',
      content: 'some content',
      toggle: 'popover',
      trigger,
    };

    Object.entries(dataset).forEach(([key, value]) => {
      target.dataset[key] = value;
    });

    document.body.appendChild(target);

    return target;
  };

  const buildPopoversApp = () => {
    initPopovers('[data-toggle="popover"]');
  };

  const triggerEvent = (target, eventName = 'mouseenter') => {
    const event = new Event(eventName);

    target.dispatchEvent(event);
  };

  afterEach(() => {
    document.body.innerHTML = '';
    destroy();
  });

  describe('initPopover', () => {
    it('attaches a GlPopover for the elements specified in the selector', async () => {
      const target = createPopoverTarget();

      buildPopoversApp();

      triggerEvent(target);

      await nextTick();
      const html = document.querySelector('.gl-popover').innerHTML;

      expect(document.querySelector('.gl-popover')).not.toBe(null);
      expect(html).toContain('default title');
      expect(html).toContain('some content');
    });

    it('supports triggering a popover via custom events', async () => {
      const trigger = 'click';
      const target = createPopoverTarget(trigger);

      buildPopoversApp();
      triggerEvent(target, trigger);

      await nextTick();

      expect(document.querySelector('.gl-popover')).not.toBe(null);
      expect(document.querySelector('.gl-popover').innerHTML).toContain('default title');
    });

    it('inits popovers on targets added after content load', async () => {
      buildPopoversApp();

      expect(document.querySelector('.gl-popover')).toBe(null);

      const trigger = 'click';
      const target = createPopoverTarget(trigger);
      triggerEvent(target, trigger);
      await nextTick();

      expect(document.querySelector('.gl-popover')).not.toBe(null);
    });
  });

  describe('dispose', () => {
    it('removes popovers that target the elements specified', async () => {
      const fakeTarget = createPopoverTarget();
      const target = createPopoverTarget();
      buildPopoversApp();
      triggerEvent(target);
      triggerEvent(createPopoverTarget());
      await nextTick();

      expect(document.querySelectorAll('.gl-popover')).toHaveLength(2);

      dispose([fakeTarget]);
      await nextTick();

      expect(document.querySelectorAll('.gl-popover')).toHaveLength(2);

      dispose([target]);
      await nextTick();

      expect(document.querySelectorAll('.gl-popover')).toHaveLength(1);
    });
  });
});
