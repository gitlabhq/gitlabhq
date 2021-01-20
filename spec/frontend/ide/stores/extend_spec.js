import extendStore from '~/ide/stores/extend';
import terminalPlugin from '~/ide/stores/plugins/terminal';
import terminalSyncPlugin from '~/ide/stores/plugins/terminal_sync';

jest.mock('~/ide/stores/plugins/terminal', () => jest.fn());
jest.mock('~/ide/stores/plugins/terminal_sync', () => jest.fn());

describe('ide/stores/extend', () => {
  let prevGon;
  let store;
  let el;

  beforeEach(() => {
    prevGon = global.gon;
    store = {};
    el = {};

    [terminalPlugin, terminalSyncPlugin].forEach((x) => {
      const plugin = jest.fn();

      x.mockImplementation(() => plugin);
    });
  });

  afterEach(() => {
    global.gon = prevGon;
    terminalPlugin.mockClear();
    terminalSyncPlugin.mockClear();
  });

  const withGonFeatures = (features) => {
    global.gon = { ...global.gon, features };
  };

  describe('terminalPlugin', () => {
    beforeEach(() => {
      extendStore(store, el);
    });

    it('is created', () => {
      expect(terminalPlugin).toHaveBeenCalledWith(el);
    });

    it('is called with store', () => {
      expect(terminalPlugin()).toHaveBeenCalledWith(store);
    });
  });

  describe('terminalSyncPlugin', () => {
    describe('when buildServiceProxy feature is enabled', () => {
      beforeEach(() => {
        withGonFeatures({ buildServiceProxy: true });

        extendStore(store, el);
      });

      it('is created', () => {
        expect(terminalSyncPlugin).toHaveBeenCalledWith(el);
      });

      it('is called with store', () => {
        expect(terminalSyncPlugin()).toHaveBeenCalledWith(store);
      });
    });

    describe('when buildServiceProxy feature is disabled', () => {
      it('is not created', () => {
        extendStore(store, el);

        expect(terminalSyncPlugin).not.toHaveBeenCalled();
      });
    });
  });
});
