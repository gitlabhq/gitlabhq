import createEventHub from '~/helpers/event_hub_factory';

describe('event bus factory', () => {
  let eventBus;

  beforeEach(() => {
    eventBus = createEventHub();
  });

  afterEach(() => {
    eventBus = null;
  });

  describe('underlying module', () => {
    let mitt;

    beforeEach(() => {
      jest.resetModules();
      jest.mock('mitt');

      // eslint-disable-next-line global-require
      mitt = require('mitt');
      mitt.mockReturnValue(() => ({}));

      const createEventHubActual = jest.requireActual('~/helpers/event_hub_factory').default;
      eventBus = createEventHubActual();
    });

    it('creates an emitter', () => {
      expect(mitt).toHaveBeenCalled();
    });
  });

  describe('instance', () => {
    it.each`
      method
      ${'on'}
      ${'once'}
      ${'off'}
      ${'emit'}
    `('binds $$method to $method ', ({ method }) => {
      expect(typeof eventBus[method]).toBe('function');
      expect(eventBus[method]).toBe(eventBus[`$${method}`]);
    });
  });

  describe('once', () => {
    const event = 'foobar';
    let handler;

    beforeEach(() => {
      jest.spyOn(eventBus, 'on');
      jest.spyOn(eventBus, 'off');
      handler = jest.fn();
      eventBus.once(event, handler);
    });

    it('calls on internally', () => {
      expect(eventBus.on).toHaveBeenCalled();
    });

    it('calls handler when event is emitted', () => {
      eventBus.emit(event);
      expect(handler).toHaveBeenCalled();
    });

    it('calls off when event is emitted', () => {
      eventBus.emit(event);
      expect(eventBus.off).toHaveBeenCalled();
    });

    it('calls the handler only once when event is emitted multiple times', () => {
      eventBus.emit(event);
      eventBus.emit(event);
      expect(handler).toHaveBeenCalledTimes(1);
    });

    describe('when the handler thows an error', () => {
      beforeEach(() => {
        handler = jest.fn().mockImplementation(() => {
          throw new Error();
        });
        eventBus.once(event, handler);
      });

      it('calls off when event is emitted', () => {
        expect(() => {
          eventBus.emit(event);
        }).toThrow();
        expect(eventBus.off).toHaveBeenCalled();
      });
    });
  });
});
