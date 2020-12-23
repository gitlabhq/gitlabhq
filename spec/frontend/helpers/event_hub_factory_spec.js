import createEventHub from '~/helpers/event_hub_factory';

const TEST_EVENT = 'foobar';
const TEST_EVENT_2 = 'testevent';

describe('event bus factory', () => {
  let eventBus;
  let handler;
  let otherHandlers;

  beforeEach(() => {
    eventBus = createEventHub();
    handler = jest.fn();
    otherHandlers = [jest.fn(), jest.fn()];
  });

  afterEach(() => {
    eventBus.dispose();
    eventBus = null;
  });

  describe('instance', () => {
    it.each`
      method
      ${'$on'}
      ${'$once'}
      ${'$off'}
      ${'$emit'}
    `('has $method method', ({ method }) => {
      expect(eventBus[method]).toEqual(expect.any(Function));
    });
  });

  describe('$on', () => {
    beforeEach(() => {
      eventBus.$on(TEST_EVENT, handler);
    });

    it('calls handler when event is emitted', () => {
      eventBus.$emit(TEST_EVENT);
      expect(handler).toHaveBeenCalledWith();
    });

    it('calls handler with multiple args', () => {
      eventBus.$emit(TEST_EVENT, 'arg1', 'arg2', 'arg3');
      expect(handler).toHaveBeenCalledWith('arg1', 'arg2', 'arg3');
    });

    it('calls handler multiple times', () => {
      eventBus.$emit(TEST_EVENT, 'arg1', 'arg2', 'arg3');
      eventBus.$emit(TEST_EVENT, 'arg1', 'arg2', 'arg3');

      expect(handler).toHaveBeenCalledTimes(2);
    });
  });

  describe('$once', () => {
    beforeEach(() => {
      eventBus.$once(TEST_EVENT, handler);
    });

    it('calls handler when event is emitted', () => {
      eventBus.$emit(TEST_EVENT);
      expect(handler).toHaveBeenCalled();
    });

    it('calls the handler only once when event is emitted multiple times', () => {
      eventBus.$emit(TEST_EVENT);
      eventBus.$emit(TEST_EVENT);
      expect(handler).toHaveBeenCalledTimes(1);
    });

    describe('when the handler thows an error', () => {
      beforeEach(() => {
        handler = jest.fn().mockImplementation(() => {
          throw new Error();
        });
        eventBus.$once(TEST_EVENT, handler);
      });

      it('calls off when event is emitted', () => {
        expect(() => {
          eventBus.$emit(TEST_EVENT);
        }).toThrow();
        expect(() => {
          eventBus.$emit(TEST_EVENT);
        }).not.toThrow();

        expect(handler).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('$off', () => {
    beforeEach(() => {
      otherHandlers.forEach((x) => eventBus.$on(TEST_EVENT, x));
      eventBus.$on(TEST_EVENT, handler);
    });

    it('can be called on event with no handlers', () => {
      expect(() => {
        eventBus.$off(TEST_EVENT_2);
      }).not.toThrow();
    });

    it('can be called on event with no handlers, with a handler', () => {
      expect(() => {
        eventBus.$off(TEST_EVENT_2, handler);
      }).not.toThrow();
    });

    it('with a handler, will no longer call that handler', () => {
      eventBus.$off(TEST_EVENT, handler);

      eventBus.$emit(TEST_EVENT);

      expect(handler).not.toHaveBeenCalled();
      expect(otherHandlers.map((x) => x.mock.calls.length)).toEqual(otherHandlers.map(() => 1));
    });

    it('without a handler, will no longer call any handlers', () => {
      eventBus.$off(TEST_EVENT);

      eventBus.$emit(TEST_EVENT);

      expect(handler).not.toHaveBeenCalled();
      expect(otherHandlers.map((x) => x.mock.calls.length)).toEqual(otherHandlers.map(() => 0));
    });
  });

  describe('$emit', () => {
    beforeEach(() => {
      otherHandlers.forEach((x) => eventBus.$on(TEST_EVENT_2, x));
      eventBus.$on(TEST_EVENT, handler);
    });

    it('only calls handlers for given type', () => {
      eventBus.$emit(TEST_EVENT, 'arg1');

      expect(handler).toHaveBeenCalledWith('arg1');
      expect(otherHandlers.map((x) => x.mock.calls.length)).toEqual(otherHandlers.map(() => 0));
    });
  });
});
