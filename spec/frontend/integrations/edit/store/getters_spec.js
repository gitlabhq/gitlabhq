import { currentKey, isInheriting, propsSource } from '~/integrations/edit/store/getters';
import createState from '~/integrations/edit/store/state';
import { mockIntegrationProps } from '../mock_data';

describe('Integration form store getters', () => {
  let state;
  const customState = { ...mockIntegrationProps, type: 'CustomState' };
  const adminState = { ...mockIntegrationProps, type: 'AdminState' };

  beforeEach(() => {
    state = createState({ customState });
  });

  describe('isInheriting', () => {
    describe('when adminState is null', () => {
      it('returns false', () => {
        expect(isInheriting(state)).toBe(false);
      });
    });

    describe('when adminState is an object', () => {
      beforeEach(() => {
        state.adminState = adminState;
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

  describe('propsSource', () => {
    beforeEach(() => {
      state.adminState = adminState;
    });

    it('equals adminState if inheriting', () => {
      expect(propsSource(state, { isInheriting: true })).toEqual(adminState);
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
