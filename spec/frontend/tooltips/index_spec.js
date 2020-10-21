import jQuery from 'jquery';
import {
  add,
  initTooltips,
  dispose,
  destroy,
  hide,
  show,
  enable,
  disable,
  fixTitle,
} from '~/tooltips';

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
    tooltipsApp = initTooltips({ selector: '.has-tooltip' });
  };

  const triggerEvent = (target, eventName = 'mouseenter') => {
    const event = new Event(eventName);

    target.dispatchEvent(event);
  };

  beforeEach(() => {
    window.gon.glTooltipsEnabled = true;
  });

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

  describe('add', () => {
    it('adds a GlTooltip for the specified elements', async () => {
      const target = createTooltipTarget();

      buildTooltipsApp();
      add([target], { title: 'custom title' });

      await tooltipsApp.$nextTick();

      expect(document.querySelector('.gl-tooltip')).not.toBe(null);
      expect(document.querySelector('.gl-tooltip').innerHTML).toContain('custom title');
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

  it.each`
    methodName   | method     | event
    ${'enable'}  | ${enable}  | ${'enable'}
    ${'disable'} | ${disable} | ${'disable'}
    ${'hide'}    | ${hide}    | ${'close'}
    ${'show'}    | ${show}    | ${'open'}
  `(
    '$methodName calls triggerEvent in tooltip app with $event event',
    async ({ method, event }) => {
      const target = createTooltipTarget();

      buildTooltipsApp();

      await tooltipsApp.$nextTick();

      jest.spyOn(tooltipsApp, 'triggerEvent');

      method([target]);

      expect(tooltipsApp.triggerEvent).toHaveBeenCalledWith(target, event);
    },
  );

  it('fixTitle calls fixTitle in tooltip app with the target specified', async () => {
    const target = createTooltipTarget();

    buildTooltipsApp();

    await tooltipsApp.$nextTick();

    jest.spyOn(tooltipsApp, 'fixTitle');

    fixTitle([target]);

    expect(tooltipsApp.fixTitle).toHaveBeenCalledWith(target);
  });

  describe('when glTooltipsEnabled feature flag is disabled', () => {
    beforeEach(() => {
      window.gon.glTooltipsEnabled = false;
    });

    it.each`
      method      | methodName    | bootstrapParams
      ${dispose}  | ${'dispose'}  | ${'dispose'}
      ${fixTitle} | ${'fixTitle'} | ${'_fixTitle'}
      ${enable}   | ${'enable'}   | ${'enable'}
      ${disable}  | ${'disable'}  | ${'disable'}
      ${hide}     | ${'hide'}     | ${'hide'}
      ${show}     | ${'show'}     | ${'show'}
      ${add}      | ${'init'}     | ${{ title: 'the title' }}
    `('delegates $methodName to bootstrap tooltip API', ({ method, bootstrapParams }) => {
      const elements = jQuery(createTooltipTarget());

      jest.spyOn(jQuery.fn, 'tooltip');

      method(elements, bootstrapParams);

      expect(elements.tooltip).toHaveBeenCalledWith(bootstrapParams);
    });
  });
});
