import {
  APPLICATION_STATUS,
  UNINSTALL_EVENT,
  UPDATE_EVENT,
  INSTALL_EVENT,
} from '~/clusters/constants';
import transitionApplicationState from '~/clusters/services/application_state_machine';

const {
  NO_STATUS,
  SCHEDULED,
  NOT_INSTALLABLE,
  INSTALLABLE,
  INSTALLING,
  INSTALLED,
  ERROR,
  UPDATING,
  UPDATED,
  UPDATE_ERRORED,
  UNINSTALLING,
  UNINSTALL_ERRORED,
  UNINSTALLED,
  PRE_INSTALLED,
  EXTERNALLY_INSTALLED,
} = APPLICATION_STATUS;

const NO_EFFECTS = 'no effects';

describe('applicationStateMachine', () => {
  const noEffectsToEmptyObject = (effects) => (typeof effects === 'string' ? {} : effects);

  describe(`current state is ${NO_STATUS}`, () => {
    it.each`
      expectedState           | event                   | effects
      ${INSTALLING}           | ${SCHEDULED}            | ${NO_EFFECTS}
      ${NOT_INSTALLABLE}      | ${NOT_INSTALLABLE}      | ${NO_EFFECTS}
      ${INSTALLABLE}          | ${INSTALLABLE}          | ${NO_EFFECTS}
      ${INSTALLING}           | ${INSTALLING}           | ${NO_EFFECTS}
      ${INSTALLED}            | ${INSTALLED}            | ${NO_EFFECTS}
      ${INSTALLABLE}          | ${ERROR}                | ${{ installFailed: true }}
      ${UPDATING}             | ${UPDATING}             | ${NO_EFFECTS}
      ${INSTALLED}            | ${UPDATED}              | ${NO_EFFECTS}
      ${INSTALLED}            | ${UPDATE_ERRORED}       | ${{ updateFailed: true }}
      ${UNINSTALLING}         | ${UNINSTALLING}         | ${NO_EFFECTS}
      ${INSTALLED}            | ${UNINSTALL_ERRORED}    | ${{ uninstallFailed: true }}
      ${UNINSTALLED}          | ${UNINSTALLED}          | ${NO_EFFECTS}
      ${PRE_INSTALLED}        | ${PRE_INSTALLED}        | ${NO_EFFECTS}
      ${EXTERNALLY_INSTALLED} | ${EXTERNALLY_INSTALLED} | ${NO_EFFECTS}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: NO_STATUS,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...noEffectsToEmptyObject(effects),
      });
    });
  });

  describe(`current state is ${NOT_INSTALLABLE}`, () => {
    it.each`
      expectedState  | event          | effects
      ${INSTALLABLE} | ${INSTALLABLE} | ${NO_EFFECTS}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: NOT_INSTALLABLE,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...noEffectsToEmptyObject(effects),
      });
    });
  });

  describe(`current state is ${INSTALLABLE}`, () => {
    it.each`
      expectedState      | event              | effects
      ${INSTALLING}      | ${INSTALL_EVENT}   | ${{ installFailed: false }}
      ${INSTALLED}       | ${INSTALLED}       | ${{ installFailed: false }}
      ${NOT_INSTALLABLE} | ${NOT_INSTALLABLE} | ${NO_EFFECTS}
      ${UNINSTALLED}     | ${UNINSTALLED}     | ${{ installFailed: false }}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: INSTALLABLE,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...noEffectsToEmptyObject(effects),
      });
    });
  });

  describe(`current state is ${INSTALLING}`, () => {
    it.each`
      expectedState  | event        | effects
      ${INSTALLED}   | ${INSTALLED} | ${NO_EFFECTS}
      ${INSTALLABLE} | ${ERROR}     | ${{ installFailed: true }}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: INSTALLING,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...noEffectsToEmptyObject(effects),
      });
    });
  });

  describe(`current state is ${INSTALLED}`, () => {
    it.each`
      expectedState      | event              | effects
      ${UPDATING}        | ${UPDATE_EVENT}    | ${{ updateFailed: false, updateSuccessful: false }}
      ${UNINSTALLING}    | ${UNINSTALL_EVENT} | ${{ uninstallFailed: false, uninstallSuccessful: false }}
      ${NOT_INSTALLABLE} | ${NOT_INSTALLABLE} | ${NO_EFFECTS}
      ${UNINSTALLED}     | ${UNINSTALLED}     | ${NO_EFFECTS}
      ${INSTALLABLE}     | ${ERROR}           | ${{ installFailed: true }}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: INSTALLED,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...noEffectsToEmptyObject(effects),
      });
    });
  });

  describe(`current state is ${UPDATING}`, () => {
    it.each`
      expectedState | event             | effects
      ${INSTALLED}  | ${UPDATED}        | ${{ updateSuccessful: true }}
      ${INSTALLED}  | ${UPDATE_ERRORED} | ${{ updateFailed: true }}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: UPDATING,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...effects,
      });
    });
  });

  describe(`current state is ${UNINSTALLING}`, () => {
    it.each`
      expectedState  | event                | effects
      ${INSTALLABLE} | ${INSTALLABLE}       | ${{ uninstallSuccessful: true }}
      ${INSTALLED}   | ${UNINSTALL_ERRORED} | ${{ uninstallFailed: true }}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: UNINSTALLING,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...effects,
      });
    });
  });

  describe(`current state is ${UNINSTALLED}`, () => {
    it.each`
      expectedState  | event        | effects
      ${INSTALLED}   | ${INSTALLED} | ${NO_EFFECTS}
      ${INSTALLABLE} | ${ERROR}     | ${{ installFailed: true }}
    `(`transitions to $expectedState on $event event and applies $effects`, (data) => {
      const { expectedState, event, effects } = data;
      const currentAppState = {
        status: UNINSTALLED,
      };

      expect(transitionApplicationState(currentAppState, event)).toEqual({
        status: expectedState,
        ...noEffectsToEmptyObject(effects),
      });
    });
  });
  describe('current state is undefined', () => {
    it('returns the current state without having any effects', () => {
      const currentAppState = {};
      expect(transitionApplicationState(currentAppState, INSTALLABLE)).toEqual(currentAppState);
    });
  });

  describe('with event is undefined', () => {
    it('returns the current state without having any effects', () => {
      const currentAppState = {
        status: NO_STATUS,
      };
      expect(transitionApplicationState(currentAppState, undefined)).toEqual(currentAppState);
    });
  });
});
