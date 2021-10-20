import DropDown from '~/filtered_search/droplab/drop_down';
import Hook from '~/filtered_search/droplab/hook';

jest.mock('~/filtered_search/droplab/drop_down', () => jest.fn());

describe('Hook', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('class constructor', () => {
    beforeEach(() => {
      testContext.trigger = { id: 'id' };
      testContext.list = {};
      testContext.plugins = {};
      testContext.config = {};

      testContext.hook = new Hook(
        testContext.trigger,
        testContext.list,
        testContext.plugins,
        testContext.config,
      );
    });

    it('should set .trigger', () => {
      expect(testContext.hook.trigger).toBe(testContext.trigger);
    });

    it('should set .list', () => {
      expect(testContext.hook.list).toEqual({});
    });

    it('should call DropDown constructor', () => {
      expect(DropDown).toHaveBeenCalledWith(testContext.list, testContext.config);
    });

    it('should set .type', () => {
      expect(testContext.hook.type).toBe('Hook');
    });

    it('should set .event', () => {
      expect(testContext.hook.event).toBe('click');
    });

    it('should set .plugins', () => {
      expect(testContext.hook.plugins).toBe(testContext.plugins);
    });

    it('should set .config', () => {
      expect(testContext.hook.config).toBe(testContext.config);
    });

    it('should set .id', () => {
      expect(testContext.hook.id).toBe(testContext.trigger.id);
    });

    describe('if config argument is undefined', () => {
      beforeEach(() => {
        testContext.config = undefined;

        testContext.hook = new Hook(
          testContext.trigger,
          testContext.list,
          testContext.plugins,
          testContext.config,
        );
      });

      it('should set .config to an empty object', () => {
        expect(testContext.hook.config).toEqual({});
      });
    });

    describe('if plugins argument is undefined', () => {
      beforeEach(() => {
        testContext.plugins = undefined;

        testContext.hook = new Hook(
          testContext.trigger,
          testContext.list,
          testContext.plugins,
          testContext.config,
        );
      });

      it('should set .plugins to an empty array', () => {
        expect(testContext.hook.plugins).toEqual([]);
      });
    });
  });
});
