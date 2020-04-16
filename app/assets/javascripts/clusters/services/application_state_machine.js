import { APPLICATION_STATUS, UPDATE_EVENT, INSTALL_EVENT, UNINSTALL_EVENT } from '../constants';

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
  PRE_INSTALLED,
} = APPLICATION_STATUS;

const applicationStateMachine = {
  /* When the application initially loads, it will have `NO_STATUS`
   * It will transition from `NO_STATUS` once the async backend call is completed
   */
  [NO_STATUS]: {
    on: {
      [SCHEDULED]: {
        target: INSTALLING,
      },
      [NOT_INSTALLABLE]: {
        target: NOT_INSTALLABLE,
      },
      [INSTALLABLE]: {
        target: INSTALLABLE,
      },
      [INSTALLING]: {
        target: INSTALLING,
      },
      [INSTALLED]: {
        target: INSTALLED,
      },
      [ERROR]: {
        target: INSTALLABLE,
        effects: {
          installFailed: true,
        },
      },
      [UPDATING]: {
        target: UPDATING,
      },
      [UPDATED]: {
        target: INSTALLED,
      },
      [UPDATE_ERRORED]: {
        target: INSTALLED,
        effects: {
          updateFailed: true,
        },
      },
      [UNINSTALLING]: {
        target: UNINSTALLING,
      },
      [UNINSTALL_ERRORED]: {
        target: INSTALLED,
        effects: {
          uninstallFailed: true,
        },
      },
      [PRE_INSTALLED]: {
        target: PRE_INSTALLED,
      },
    },
  },
  [NOT_INSTALLABLE]: {
    on: {
      [INSTALLABLE]: {
        target: INSTALLABLE,
      },
    },
  },
  [INSTALLABLE]: {
    on: {
      [INSTALL_EVENT]: {
        target: INSTALLING,
        effects: {
          installFailed: false,
        },
      },
      [NOT_INSTALLABLE]: {
        target: NOT_INSTALLABLE,
      },
      // This is possible in artificial environments for E2E testing
      [INSTALLED]: {
        target: INSTALLED,
      },
    },
  },
  [INSTALLING]: {
    on: {
      [INSTALLED]: {
        target: INSTALLED,
      },
      [ERROR]: {
        target: INSTALLABLE,
        effects: {
          installFailed: true,
        },
      },
    },
  },
  [INSTALLED]: {
    on: {
      [UPDATE_EVENT]: {
        target: UPDATING,
        effects: {
          updateFailed: false,
          updateSuccessful: false,
        },
      },
      [NOT_INSTALLABLE]: {
        target: NOT_INSTALLABLE,
      },
      [UNINSTALL_EVENT]: {
        target: UNINSTALLING,
        effects: {
          uninstallFailed: false,
          uninstallSuccessful: false,
        },
      },
    },
  },
  [PRE_INSTALLED]: {
    on: {
      [UPDATE_EVENT]: {
        target: UPDATING,
        effects: {
          updateFailed: false,
          updateSuccessful: false,
        },
      },
      [NOT_INSTALLABLE]: {
        target: NOT_INSTALLABLE,
      },
      [UNINSTALL_EVENT]: {
        target: UNINSTALLING,
        effects: {
          uninstallFailed: false,
          uninstallSuccessful: false,
        },
      },
    },
  },
  [UPDATING]: {
    on: {
      [UPDATED]: {
        target: INSTALLED,
        effects: {
          updateSuccessful: true,
        },
      },
      [UPDATE_ERRORED]: {
        target: INSTALLED,
        effects: {
          updateFailed: true,
        },
      },
    },
  },
  [UNINSTALLING]: {
    on: {
      [INSTALLABLE]: {
        target: INSTALLABLE,
        effects: {
          uninstallSuccessful: true,
        },
      },
      [UNINSTALL_ERRORED]: {
        target: INSTALLED,
        effects: {
          uninstallFailed: true,
        },
      },
    },
  },
};

/**
 * Determines an application new state based on the application current state
 * and an event. If the application current state cannot handle a given event,
 * the current state is returned.
 *
 * @param {*} application
 * @param {*} event
 */
const transitionApplicationState = (application, event) => {
  const stateMachine = applicationStateMachine[application.status];
  const newState = stateMachine !== undefined ? stateMachine.on[event] : false;

  return newState
    ? {
        ...application,
        status: newState.target,
        ...newState.effects,
      }
    : application;
};

export default transitionApplicationState;
