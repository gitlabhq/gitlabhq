import {
  currentKey,
  isInheriting,
  isDisabled,
  propsSource,
} from '~/integrations/edit/store/getters';
import createState from '~/integrations/edit/store/state';
import mutations from '~/integrations/edit/store/mutations';
import * as types from '~/integrations/edit/store/mutation_types';
import { mockIntegrationProps } from '../mock_data';

describe('Integration form store getters', () => {
  let state;
  const customState = { ...mockIntegrationProps, type: 'CustomState' };
  const defaultState = { ...mockIntegrationProps, type: 'DefaultState' };

  beforeEach(() => {
    state = createState({ customState });
  });

  describe('isInheriting', () => {
    describe('when defaultState is null', () => {
      it('returns false', () => {
        expect(isInheriting(state)).toBe(false);
      });
    });

    describe('when defaultState is an object', () => {
      beforeEach(() => {
        state.defaultState = defaultState;
      });

      describe('when override is false', () => {
        beforeEach(() => {
          state.override = false;
        });

        it('returns false', () => {
          expect(isInheriting(state)).toBe(true);
        });
      });

      describe('when override is true', () => {
        beforeEach(() => {
          state.override = true;
        });

        it('returns true', () => {
          expect(isInheriting(state)).toBe(false);
        });
      });
    });
  });

  describe('isDisabled', () => {
    it.each`
      isSaving | isTesting | isResetting | expected
      ${false} | ${false}  | ${false}    | ${false}
      ${true}  | ${false}  | ${false}    | ${true}
      ${false} | ${true}   | ${false}    | ${true}
      ${false} | ${false}  | ${true}     | ${true}
      ${false} | ${true}   | ${true}     | ${true}
      ${true}  | ${false}  | ${true}     | ${true}
      ${true}  | ${true}   | ${false}    | ${true}
      ${true}  | ${true}   | ${true}     | ${true}
    `(
      'when isSaving = $isSaving, isTesting = $isTesting, isResetting = $isResetting then isDisabled = $expected',
      ({ isSaving, isTesting, isResetting, expected }) => {
        mutations[types.SET_IS_SAVING](state, isSaving);
        mutations[types.SET_IS_TESTING](state, isTesting);
        mutations[types.SET_IS_RESETTING](state, isResetting);

        expect(isDisabled(state)).toBe(expected);
      },
    );
  });

  describe('propsSource', () => {
    beforeEach(() => {
      state.defaultState = defaultState;
    });

    it('equals defaultState if inheriting', () => {
      expect(propsSource(state, { isInheriting: true })).toEqual(defaultState);
    });

    it('equals customState if not inheriting', () => {
      expect(propsSource(state, { isInheriting: false })).toEqual(customState);
    });
  });

  describe('currentKey', () => {
    it('equals `admin` if inheriting', () => {
      expect(currentKey(state, { isInheriting: true })).toEqual('admin');
    });

    it('equals `custom` if not inheriting', () => {
      expect(currentKey(state, { isInheriting: false })).toEqual('custom');
    });
  });
});
