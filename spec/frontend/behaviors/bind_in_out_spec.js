import BindInOut from '~/behaviors/bind_in_out';

describe('BindInOut', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('constructor', () => {
    beforeEach(() => {
      testContext.in = {};
      testContext.out = {};

      testContext.bindInOut = new BindInOut(testContext.in, testContext.out);
    });

    it('should set .in', () => {
      expect(testContext.bindInOut.in).toBe(testContext.in);
    });

    it('should set .out', () => {
      expect(testContext.bindInOut.out).toBe(testContext.out);
    });

    it('should set .eventWrapper', () => {
      expect(testContext.bindInOut.eventWrapper).toEqual({});
    });

    describe('if .in is an input', () => {
      beforeEach(() => {
        testContext.bindInOut = new BindInOut({ tagName: 'INPUT' });
      });

      it('should set .eventType to keyup', () => {
        expect(testContext.bindInOut.eventType).toEqual('keyup');
      });
    });

    describe('if .in is a textarea', () => {
      beforeEach(() => {
        testContext.bindInOut = new BindInOut({ tagName: 'TEXTAREA' });
      });

      it('should set .eventType to keyup', () => {
        expect(testContext.bindInOut.eventType).toEqual('keyup');
      });
    });

    describe('if .in is not an input or textarea', () => {
      beforeEach(() => {
        testContext.bindInOut = new BindInOut({ tagName: 'SELECT' });
      });

      it('should set .eventType to change', () => {
        expect(testContext.bindInOut.eventType).toEqual('change');
      });
    });
  });

  describe('addEvents', () => {
    beforeEach(() => {
      testContext.in = {
        addEventListener: jest.fn(),
      };

      testContext.bindInOut = new BindInOut(testContext.in);

      testContext.addEvents = testContext.bindInOut.addEvents();
    });

    it('should set .eventWrapper.updateOut', () => {
      expect(testContext.bindInOut.eventWrapper.updateOut).toEqual(expect.any(Function));
    });

    it('should call .addEventListener', () => {
      expect(testContext.in.addEventListener).toHaveBeenCalledWith(
        testContext.bindInOut.eventType,
        testContext.bindInOut.eventWrapper.updateOut,
      );
    });

    it('should return the instance', () => {
      expect(testContext.addEvents).toBe(testContext.bindInOut);
    });
  });

  describe('updateOut', () => {
    beforeEach(() => {
      testContext.in = { value: 'the-value' };
      testContext.out = { textContent: 'not-the-value' };

      testContext.bindInOut = new BindInOut(testContext.in, testContext.out);

      testContext.updateOut = testContext.bindInOut.updateOut();
    });

    it('should set .out.textContent to .in.value', () => {
      expect(testContext.out.textContent).toBe(testContext.in.value);
    });

    it('should return the instance', () => {
      expect(testContext.updateOut).toBe(testContext.bindInOut);
    });
  });

  describe('removeEvents', () => {
    beforeEach(() => {
      testContext.in = {
        removeEventListener: jest.fn(),
      };
      testContext.updateOut = () => {};

      testContext.bindInOut = new BindInOut(testContext.in);
      testContext.bindInOut.eventWrapper.updateOut = testContext.updateOut;

      testContext.removeEvents = testContext.bindInOut.removeEvents();
    });

    it('should call .removeEventListener', () => {
      expect(testContext.in.removeEventListener).toHaveBeenCalledWith(
        testContext.bindInOut.eventType,
        testContext.updateOut,
      );
    });

    it('should return the instance', () => {
      expect(testContext.removeEvents).toBe(testContext.bindInOut);
    });
  });

  describe('initAll', () => {
    beforeEach(() => {
      testContext.ins = [0, 1, 2];
      testContext.instances = [];

      jest.spyOn(document, 'querySelectorAll').mockReturnValue(testContext.ins);
      jest.spyOn(Array.prototype, 'map');
      jest.spyOn(BindInOut, 'init').mockImplementation(() => {});

      testContext.initAll = BindInOut.initAll();
    });

    it('should be a static method', () => {
      expect(BindInOut.initAll).toEqual(expect.any(Function));
    });

    it('should call .querySelectorAll', () => {
      expect(document.querySelectorAll).toHaveBeenCalledWith('*[data-bind-in]');
    });

    it('should call .map', () => {
      expect(Array.prototype.map).toHaveBeenCalledWith(expect.any(Function));
    });

    it('should call .init for each element', () => {
      expect(BindInOut.init.mock.calls.length).toEqual(3);
    });

    it('should return an array of instances', () => {
      expect(testContext.initAll).toEqual(expect.any(Array));
    });
  });

  describe('init', () => {
    beforeEach(() => {
      jest.spyOn(BindInOut.prototype, 'addEvents').mockReturnThis();
      jest.spyOn(BindInOut.prototype, 'updateOut').mockReturnThis();

      testContext.init = BindInOut.init({}, {});
    });

    it('should be a static method', () => {
      expect(BindInOut.init).toEqual(expect.any(Function));
    });

    it('should call .addEvents', () => {
      expect(BindInOut.prototype.addEvents).toHaveBeenCalled();
    });

    it('should call .updateOut', () => {
      expect(BindInOut.prototype.updateOut).toHaveBeenCalled();
    });

    describe('if no anOut is provided', () => {
      beforeEach(() => {
        testContext.anIn = { dataset: { bindIn: 'the-data-bind-in' } };

        jest.spyOn(document, 'querySelector').mockImplementation(() => {});

        BindInOut.init(testContext.anIn);
      });

      it('should call .querySelector', () => {
        expect(document.querySelector).toHaveBeenCalledWith(
          `*[data-bind-out="${testContext.anIn.dataset.bindIn}"]`,
        );
      });
    });
  });
});
