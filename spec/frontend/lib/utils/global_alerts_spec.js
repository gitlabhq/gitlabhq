import {
  getGlobalAlerts,
  setGlobalAlerts,
  removeGlobalAlertById,
  GLOBAL_ALERTS_SESSION_STORAGE_KEY,
  GLOBAL_ALERTS_DISMISS_EVENT,
  dismissGlobalAlertById,
  eventHub,
} from '~/lib/utils/global_alerts';

describe('global alerts utils', () => {
  describe('getGlobalAlerts', () => {
    describe('when there are alerts', () => {
      beforeEach(() => {
        jest
          .spyOn(Storage.prototype, 'getItem')
          .mockImplementation(() => '[{"id":"foo","variant":"danger","message":"Foo"}]');
      });

      it('returns alerts from session storage', () => {
        expect(getGlobalAlerts()).toEqual([{ id: 'foo', variant: 'danger', message: 'Foo' }]);
      });
    });

    describe('when there are no alerts', () => {
      beforeEach(() => {
        jest.spyOn(Storage.prototype, 'getItem').mockImplementation(() => null);
      });

      it('returns empty array', () => {
        expect(getGlobalAlerts()).toEqual([]);
      });
    });
  });
});

describe('setGlobalAlerts', () => {
  it('sets alerts in session storage', () => {
    const setItemSpy = jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {});

    setGlobalAlerts([
      {
        id: 'foo',
        variant: 'danger',
        message: 'Foo',
      },
      {
        id: 'bar',
        variant: 'success',
        message: 'Bar',
        persistOnPages: ['dashboard:groups:index'],
        dismissible: false,
      },
    ]);

    expect(setItemSpy).toHaveBeenCalledWith(
      GLOBAL_ALERTS_SESSION_STORAGE_KEY,
      '[{"dismissible":true,"persistOnPages":[],"id":"foo","variant":"danger","message":"Foo"},{"dismissible":false,"persistOnPages":["dashboard:groups:index"],"id":"bar","variant":"success","message":"Bar"}]',
    );
  });
});

describe('removeGlobalAlertById', () => {
  beforeEach(() => {
    jest
      .spyOn(Storage.prototype, 'getItem')
      .mockImplementation(
        () =>
          '[{"id":"foo","variant":"success","message":"Foo"},{"id":"bar","variant":"danger","message":"Bar"}]',
      );
  });

  it('removes alert', () => {
    const setItemSpy = jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {});

    removeGlobalAlertById('bar');

    expect(setItemSpy).toHaveBeenCalledWith(
      GLOBAL_ALERTS_SESSION_STORAGE_KEY,
      '[{"id":"foo","variant":"success","message":"Foo"}]',
    );
  });
});

describe('dismissGlobalAlertById', () => {
  beforeEach(() => {
    jest.spyOn(eventHub, '$emit').mockImplementation();
  });

  it(`fires the "${GLOBAL_ALERTS_DISMISS_EVENT}" event`, () => {
    dismissGlobalAlertById('bar');

    expect(eventHub.$emit).toHaveBeenCalledTimes(1);
    expect(eventHub.$emit).toHaveBeenCalledWith(GLOBAL_ALERTS_DISMISS_EVENT, 'bar');
  });
});
