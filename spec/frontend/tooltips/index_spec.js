import { initTooltips, dispose, destroy } from '~/tooltips';

describe('tooltips/index.js', () => {
  let tooltipsApp;

  const createTooltipTarget = () => {
    const target = document.createElement('button');
    const attributes = {
      title: 'default title',
    };

    Object.keys(attributes).forEach(name => {
      target.setAttribute(name, attributes[name]);
    });

    target.classList.add('has-tooltip');

    document.body.appendChild(target);

    return target;
  };

  const buildTooltipsApp = () => {
    tooltipsApp = initTooltips('.has-tooltip');
  };

  const triggerEvent = (target, eventName = 'mouseenter') => {
    const event = new Event(eventName);

    target.dispatchEvent(event);
  };

  afterEach(() => {
    document.body.childNodes.forEach(node => node.remove());
    destroy();
  });

  describe('initTooltip', () => {
    it('attaches a GlTooltip for the elements specified in the selector', async () => {
      const target = createTooltipTarget();

      buildTooltipsApp();

      triggerEvent(target);

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).not.toBe(null);
      expect(document.querySelector('.gl-tooltip').innerHTML).toContain('default title');
    });

    it('supports triggering a tooltip in custom events', async () => {
      const target = createTooltipTarget();

      buildTooltipsApp();
      triggerEvent(target, 'click');

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).not.toBe(null);
      expect(document.querySelector('.gl-tooltip').innerHTML).toContain('default title');
    });
  });

  describe('dispose', () => {
    it('removes tooltips that target the elements specified', async () => {
      const target = createTooltipTarget();

      buildTooltipsApp();
      triggerEvent(target);

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).not.toBe(null);

      dispose([target]);

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).toBe(null);
    });
  });
});
