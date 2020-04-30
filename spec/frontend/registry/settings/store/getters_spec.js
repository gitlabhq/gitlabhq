import * as getters from '~/registry/settings/store/getters';
import * as utils from '~/registry/shared/utils';
import { formOptions } from '../../shared/mock_data';

describe('Getters registry settings store', () => {
  const settings = {
    enabled: true,
    cadence: 'foo',
    keep_n: 'bar',
    older_than: 'baz',
    name_regex: 'name-foo',
    name_regex_keep: 'name-keep-bar',
  };

  describe.each`
    getter            | variable        | formOption
    ${'getCadence'}   | ${'cadence'}    | ${'cadence'}
    ${'getKeepN'}     | ${'keep_n'}     | ${'keepN'}
    ${'getOlderThan'} | ${'older_than'} | ${'olderThan'}
  `('Options getter', ({ getter, variable, formOption }) => {
    beforeEach(() => {
      utils.findDefaultOption = jest.fn();
    });

    it(`${getter} returns ${variable} when ${variable} exists in settings`, () => {
      expect(getters[getter]({ settings })).toBe(settings[variable]);
    });

    it(`${getter} calls findDefaultOption when ${variable} does not exists in settings`, () => {
      getters[getter]({ settings: {}, formOptions });
      expect(utils.findDefaultOption).toHaveBeenCalledWith(formOptions[formOption]);
    });
  });

  describe('getSettings', () => {
    it('returns the content of settings', () => {
      const computedGetters = {
        getCadence: settings.cadence,
        getOlderThan: settings.older_than,
        getKeepN: settings.keep_n,
      };
      expect(getters.getSettings({ settings }, computedGetters)).toEqual(settings);
    });
  });

  describe('getIsEdited', () => {
    it('returns false when original is equal to settings', () => {
      const same = { foo: 'bar' };
      expect(getters.getIsEdited({ original: same, settings: same })).toBe(false);
    });

    it('returns true when original is different from settings', () => {
      expect(getters.getIsEdited({ original: { foo: 'bar' }, settings: { foo: 'baz' } })).toBe(
        true,
      );
    });
  });

  describe('getIsDisabled', () => {
    it.each`
      original          | enableHistoricEntries | result
      ${undefined}      | ${false}              | ${true}
      ${{ foo: 'bar' }} | ${undefined}          | ${false}
      ${{}}             | ${false}              | ${false}
    `(
      'returns $result when original is $original and enableHistoricEntries is $enableHistoricEntries',
      ({ original, enableHistoricEntries, result }) => {
        expect(getters.getIsDisabled({ original, enableHistoricEntries })).toBe(result);
      },
    );
  });
});
