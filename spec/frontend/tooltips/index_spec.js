import { initTooltips } from '~/tooltips';

describe('tooltips/index.js', () => {
  const createTooltipTarget = () => {
    const target = document.createElement('button');
    const attributes = {
      title: 'default title',
    };

    Object.keys(attributes).forEach(name => {
      target.setAttribute(name, attributes[name]);
    });

    target.classList.add('has-tooltip');

    return target;
  };

  const triggerEvent = (target, eventName = 'mouseenter') => {
    const event = new Event(eventName);

    target.dispatchEvent(event);
  };

  describe('initTooltip', () => {
    it('attaches a GlTooltip for the elements specified in the selector', async () => {
      const target = createTooltipTarget();
      const tooltipsApp = initTooltips('.has-tooltip');

      document.body.appendChild(tooltipsApp.$el);
      document.body.appendChild(target);

      triggerEvent(target);

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).not.toBe(null);
      expect(document.querySelector('.gl-tooltip').innerHTML).toContain('default title');
    });

    it('supports triggering a tooltip in custom events', async () => {
      const target = createTooltipTarget();
      const tooltipsApp = initTooltips('.has-tooltip', {
        triggers: 'click',
      });

      document.body.appendChild(tooltipsApp.$el);
      document.body.appendChild(target);

      triggerEvent(target, 'click');

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).not.toBe(null);
      expect(document.querySelector('.gl-tooltip').innerHTML).toContain('default title');
    });
  });
});
