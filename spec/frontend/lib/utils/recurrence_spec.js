import { create, free, recall } from '~/lib/utils/recurrence';

const HEX = /[a-f0-9]/i;
const HEX_RE = HEX.source;
const UUIDV4 = new RegExp(
  `${HEX_RE}{8}-${HEX_RE}{4}-4${HEX_RE}{3}-[89ab]${HEX_RE}{3}-${HEX_RE}{12}`,
  'i',
);

describe('recurrence', () => {
  let recurInstance;
  let id;

  beforeEach(() => {
    recurInstance = create();
    id = recurInstance.id;
  });

  afterEach(() => {
    id = null;
    recurInstance.free();
  });

  describe('create', () => {
    it('returns an object with the correct external api', () => {
      expect(recurInstance).toMatchObject(
        expect.objectContaining({
          id: expect.stringMatching(UUIDV4),
          count: 0,
          handlers: {},
          free: expect.any(Function),
          handle: expect.any(Function),
          eject: expect.any(Function),
          occur: expect.any(Function),
          reset: expect.any(Function),
        }),
      );
    });
  });

  describe('recall', () => {
    it('returns a previously created RecurInstance', () => {
      expect(recall(id).id).toBe(id);
    });

    it("returns undefined if the provided UUID doesn't refer to a stored RecurInstance", () => {
      expect(recall('1234')).toBeUndefined();
    });
  });

  describe('free', () => {
    it('returns true when the RecurInstance exists', () => {
      expect(free(id)).toBe(true);
    });

    it("returns false when the ID doesn't refer to a known RecurInstance", () => {
      expect(free('1234')).toBe(false);
    });

    it('removes the correct RecurInstance from the list of references', () => {
      const anotherInstance = create();

      expect(recall(id)).toEqual(recurInstance);
      expect(recall(anotherInstance.id)).toEqual(anotherInstance);

      free(id);

      expect(recall(id)).toBeUndefined();
      expect(recall(anotherInstance.id)).toEqual(anotherInstance);

      anotherInstance.free();
    });
  });

  describe('RecurInstance (`create()` return value)', () => {
    it.each`
      property      | value                            | alias
      ${'id'}       | ${expect.stringMatching(UUIDV4)} | ${'[a string matching the UUIDv4 specification]'}
      ${'count'}    | ${0}                             | ${0}
      ${'handlers'} | ${{}}                            | ${{}}
    `(
      'has the correct primitive value $alias for the member `$property` to start',
      ({ property, value }) => {
        expect(recurInstance[property]).toEqual(value);
      },
    );

    describe('id', () => {
      it('cannot be changed manually', () => {
        expect(() => {
          recurInstance.id = 'new-id';
        }).toThrow(TypeError);

        expect(recurInstance.id).toBe(id);
      });

      it.each`
        method
        ${'free'}
        ${'handle'}
        ${'eject'}
        ${'occur'}
        ${'reset'}
      `('does not change across any method call - like after `$method`', ({ method }) => {
        recurInstance[method]();

        expect(recurInstance.id).toBe(id);
      });
    });

    describe('count', () => {
      it('cannot be changed manually', () => {
        expect(() => {
          recurInstance.count = 9999;
        }).toThrow(TypeError);

        expect(recurInstance.count).toBe(0);
      });

      it.each`
        method
        ${'free'}
        ${'handle'}
        ${'eject'}
        ${'reset'}
      `("doesn't change in unexpected scenarios - like after a call to `$method`", ({ method }) => {
        recurInstance[method]();

        expect(recurInstance.count).toBe(0);
      });

      it('increments by one each time `.occur()` is called', () => {
        expect(recurInstance.count).toBe(0);
        recurInstance.occur();
        expect(recurInstance.count).toBe(1);
        recurInstance.occur();
        expect(recurInstance.count).toBe(2);
      });
    });

    describe('handlers', () => {
      it('cannot be changed manually', () => {
        const fn = jest.fn();

        recurInstance.handle(1, fn);
        expect(() => {
          recurInstance.handlers = {};
        }).toThrow(TypeError);

        expect(recurInstance.handlers).toStrictEqual({
          1: fn,
        });
      });

      it.each`
        method
        ${'free'}
        ${'occur'}
        ${'eject'}
        ${'reset'}
      `("doesn't change in unexpected scenarios - like after a call to `$method`", ({ method }) => {
        recurInstance[method]();

        expect(recurInstance.handlers).toEqual({});
      });

      it('adds handlers to the correct slots', () => {
        const fn1 = jest.fn();
        const fn2 = jest.fn();

        recurInstance.handle(100, fn1);
        recurInstance.handle(1000, fn2);

        expect(recurInstance.handlers).toMatchObject({
          100: fn1,
          1000: fn2,
        });
      });
    });

    describe('free', () => {
      it('removes itself from recallable memory', () => {
        expect(recall(id)).toEqual(recurInstance);

        recurInstance.free();

        expect(recall(id)).toBeUndefined();
      });
    });

    describe('handle', () => {
      it('adds a handler for the provided count', () => {
        const fn = jest.fn();

        recurInstance.handle(5, fn);

        expect(recurInstance.handlers[5]).toEqual(fn);
      });

      it("doesn't add any handlers if either the count or behavior aren't provided", () => {
        const fn = jest.fn();

        recurInstance.handle(null, fn);
        // Note that it's not possible to react to something not happening (without timers)
        recurInstance.handle(0, fn);
        recurInstance.handle(5, null);

        expect(recurInstance.handlers).toEqual({});
      });
    });

    describe('eject', () => {
      it('removes the handler assigned to the particular count slot', () => {
        const func = jest.fn();
        recurInstance.handle(1, func);

        expect(recurInstance.handlers[1]).toStrictEqual(func);

        recurInstance.eject(1);

        expect(recurInstance.handlers).toEqual({});
      });

      it("succeeds (or fails gracefully) when the count provided doesn't have a handler assigned", () => {
        recurInstance.eject('abc');
        recurInstance.eject(1);

        expect(recurInstance.handlers).toEqual({});
      });

      it('makes no changes if no count is provided', () => {
        const fn = jest.fn();

        recurInstance.handle(1, fn);

        recurInstance.eject();

        expect(recurInstance.handlers[1]).toStrictEqual(fn);
      });
    });

    describe('occur', () => {
      it('increments the .count property by 1', () => {
        expect(recurInstance.count).toBe(0);

        recurInstance.occur();

        expect(recurInstance.count).toBe(1);
      });

      it('calls the appropriate handlers', () => {
        const fn1 = jest.fn();
        const fn5 = jest.fn();
        const fn10 = jest.fn();

        recurInstance.handle(1, fn1);
        recurInstance.handle(5, fn5);
        recurInstance.handle(10, fn10);

        expect(fn1).not.toHaveBeenCalled();
        expect(fn5).not.toHaveBeenCalled();
        expect(fn10).not.toHaveBeenCalled();

        recurInstance.occur();

        expect(fn1).toHaveBeenCalledTimes(1);
        expect(fn5).not.toHaveBeenCalled();
        expect(fn10).not.toHaveBeenCalled();

        recurInstance.occur();
        recurInstance.occur();
        recurInstance.occur();
        recurInstance.occur();

        expect(fn1).toHaveBeenCalledTimes(1);
        expect(fn5).toHaveBeenCalledTimes(1);
        expect(fn10).not.toHaveBeenCalled();

        recurInstance.occur();
        recurInstance.occur();
        recurInstance.occur();
        recurInstance.occur();
        recurInstance.occur();

        expect(fn1).toHaveBeenCalledTimes(1);
        expect(fn5).toHaveBeenCalledTimes(1);
        expect(fn10).toHaveBeenCalledTimes(1);
      });
    });

    describe('reset', () => {
      it('resets the count only, by default', () => {
        const fn = jest.fn();

        recurInstance.handle(3, fn);
        recurInstance.occur();
        recurInstance.occur();

        expect(recurInstance.count).toBe(2);

        recurInstance.reset();

        expect(recurInstance.count).toBe(0);
        expect(recurInstance.handlers).toEqual({ 3: fn });
      });

      it('also resets the handlers, by specific request', () => {
        const fn = jest.fn();

        recurInstance.handle(3, fn);
        recurInstance.occur();
        recurInstance.occur();

        expect(recurInstance.count).toBe(2);

        recurInstance.reset({ handlersList: true });

        expect(recurInstance.count).toBe(0);
        expect(recurInstance.handlers).toEqual({});
      });

      it('leaves the count in place, by request', () => {
        recurInstance.occur();
        recurInstance.occur();

        expect(recurInstance.count).toBe(2);

        recurInstance.reset({ currentCount: false });

        expect(recurInstance.count).toBe(2);
      });
    });
  });
});
