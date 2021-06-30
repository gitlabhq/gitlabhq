/**
 * @module finite_state_machine
 */

/**
 * The states to be used with state machine definitions
 * @typedef {Object} FiniteStateMachineStates
 * @property {!Object} ANY_KEY - Any key that maps to a known state
 * @property {!Object} ANY_KEY.on - A dictionary of transition events for the ANY_KEY state that map to a different state
 * @property {!String} ANY_KEY.on.ANY_EVENT - The resulting state that the machine should end at
 */

/**
 * An object whose minimum definition defined here can be used to guard UI state transitions
 * @typedef {Object} StatelessFiniteStateMachineDefinition
 * @property {FiniteStateMachineStates} states
 */

/**
 * An object whose minimum definition defined here can be used to create a live finite state machine
 * @typedef {Object} LiveFiniteStateMachineDefinition
 * @property {String} initial - The initial state for this machine
 * @property {FiniteStateMachineStates} states
 */

/**
 * An object that allows interacting with a stateful, live finite state machine
 * @typedef {Object} LiveStateMachine
 * @property {String} value - The current state of this machine
 * @property {Object} states - The states from when the machine definition was constructed
 * @property {Function} is - {@link module:finite_state_machine~is LiveStateMachine.is}
 * @property {Function} send - {@link module:finite_state_machine~send LiveStatemachine.send}
 */

// This is not user-facing functionality
/* eslint-disable @gitlab/require-i18n-strings */

function hasKeys(object, keys) {
  return keys.every((key) => Object.keys(object).includes(key));
}

/**
 * Get an updated state given a machine definition, a starting state, and a transition event
 * @param {StatelessFiniteStateMachineDefinition} definition
 * @param {String} current - The current known state
 * @param {String} event - A transition event
 * @returns {String} A state value
 */
export function transition(definition, current, event) {
  return definition?.states?.[current]?.on[event] || current;
}

function startMachine({ states, initial } = {}) {
  let current = initial;

  return {
    /**
     * A convenience function to test arbitrary input against the machine's current state
     * @param {String} testState - The value to test against the machine's current state
     */
    is(testState) {
      return current === testState;
    },
    /**
     * A function to transition the live state machine using an arbitrary event
     * @param {String} event - The event to send to the machine
     * @returns {String} A string representing the current state. Note this may not have changed if the current state + transition event combination are not valid.
     */
    send(event) {
      current = transition({ states }, current, event);

      return current;
    },
    get value() {
      return current;
    },
    set value(forcedState) {
      current = forcedState;
    },
    states,
  };
}

/**
 * Create a live state machine
 * @param {LiveFiniteStateMachineDefinition} definition
 * @returns {LiveStateMachine} A live state machine
 */
export function machine(definition) {
  if (!hasKeys(definition, ['initial', 'states'])) {
    throw new Error(
      'A state machine must have an initial state (`.initial`) and a dictionary of possible states (`.states`)',
    );
  } else if (!hasKeys(definition.states, [definition.initial])) {
    throw new Error(
      `Cannot initialize the state machine to state '${definition.initial}'. Is that one of the machine's defined states?`,
    );
  } else {
    return startMachine(definition);
  }
}
