import mutations from '~/registry/settings/store/mutations';
import * as types from '~/registry/settings/store/mutation_types';
import createState from '~/registry/settings/store/state';
import { formOptions, stringifiedFormOptions } from '../../shared/mock_data';

describe('Mutations Registry Store', () => {
  let mockState;

  beforeEach(() => {
    mockState = createState();
  });

  describe('SET_INITIAL_STATE', () => {
    it('should set the initial state', () => {
      const payload = {
        projectId: 'foo',
        enableHistoricEntries: false,
        adminSettingsPath: 'foo',
        isAdmin: true,
      };
      const expectedState = { ...mockState, ...payload, formOptions };
      mutations[types.SET_INITIAL_STATE](mockState, {
        ...payload,
        ...stringifiedFormOptions,
      });

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('UPDATE_SETTINGS', () => {
    it('should update the settings', () => {
      mockState.settings = { foo: 'bar' };
      const payload = { foo: 'baz' };
      const expectedState = { ...mockState, settings: payload };
      mutations[types.UPDATE_SETTINGS](mockState, { settings: payload });
      expect(mockState.settings).toEqual(expectedState.settings);
    });
  });

  describe('SET_SETTINGS', () => {
    it('should set the settings and original', () => {
      const payload = { foo: 'baz' };
      const expectedState = { ...mockState, settings: payload };
      mutations[types.SET_SETTINGS](mockState, payload);
      expect(mockState.settings).toEqual(expectedState.settings);
      expect(mockState.original).toEqual(expectedState.settings);
    });

    it('should keep the default state when settings is not present', () => {
      const originalSettings = { ...mockState.settings };
      mutations[types.SET_SETTINGS](mockState);
      expect(mockState.settings).toEqual(originalSettings);
      expect(mockState.original).toEqual(undefined);
    });
  });

  describe('RESET_SETTINGS', () => {
    it('should copy original over settings', () => {
      mockState.settings = { foo: 'bar' };
      mockState.original = { foo: 'baz' };
      mutations[types.RESET_SETTINGS](mockState);
      expect(mockState.settings).toEqual(mockState.original);
    });

    it('if original is undefined it should initialize to empty object', () => {
      mockState.settings = { foo: 'bar' };
      mockState.original = undefined;
      mutations[types.RESET_SETTINGS](mockState);
      expect(mockState.settings).toEqual({});
    });
  });

  describe('TOGGLE_LOADING', () => {
    it('should toggle the loading', () => {
      mutations[types.TOGGLE_LOADING](mockState);
      expect(mockState.isLoading).toEqual(true);
    });
  });
});
