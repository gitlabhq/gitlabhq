import createEventHub from '~/helpers/event_hub_factory';

const TEST_EVENT = 'foobar';

describe('event bus factory', () => {
  let eventBus;
  let handler;

  beforeEach(() => {
    eventBus = createEventHub();
    handler = jest.fn();
  });

  afterEach(() => {
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

    it('does not call handler after $off with handler', () => {
      eventBus.$off(TEST_EVENT, handler);

      eventBus.$emit(TEST_EVENT);

      expect(handler).not.toHaveBeenCalled();
    });

    it('does not call handler after $off', () => {
      eventBus.$off(TEST_EVENT);

      eventBus.$emit(TEST_EVENT);

      expect(handler).not.toHaveBeenCalled();
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
});
