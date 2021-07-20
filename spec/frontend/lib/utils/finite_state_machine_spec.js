import { machine, transition } from '~/lib/utils/finite_state_machine';

describe('Finite State Machine', () => {
  const STATE_IDLE = 'idle';
  const STATE_LOADING = 'loading';
  const STATE_ERRORED = 'errored';

  const TRANSITION_START_LOAD = 'START_LOAD';
  const TRANSITION_LOAD_ERROR = 'LOAD_ERROR';
  const TRANSITION_LOAD_SUCCESS = 'LOAD_SUCCESS';
  const TRANSITION_ACKNOWLEDGE_ERROR = 'ACKNOWLEDGE_ERROR';

  const definition = {
    initial: STATE_IDLE,
    states: {
      [STATE_IDLE]: {
        on: {
          [TRANSITION_START_LOAD]: STATE_LOADING,
        },
      },
      [STATE_LOADING]: {
        on: {
          [TRANSITION_LOAD_ERROR]: STATE_ERRORED,
          [TRANSITION_LOAD_SUCCESS]: STATE_IDLE,
        },
      },
      [STATE_ERRORED]: {
        on: {
          [TRANSITION_ACKNOWLEDGE_ERROR]: STATE_IDLE,
          [TRANSITION_START_LOAD]: STATE_LOADING,
        },
      },
    },
  };

  describe('machine', () => {
    const STATE_IMPOSSIBLE = 'impossible';
    const badDefinition = {
      init: definition.initial,
      badKeyShouldBeStates: definition.states,
    };
    const unstartableDefinition = {
      initial: STATE_IMPOSSIBLE,
      states: definition.states,
    };
    let liveMachine;

    beforeEach(() => {
      liveMachine = machine(definition);
    });

    it('throws an error if the machine definition is invalid', () => {
      expect(() => machine(badDefinition)).toThrowError(
        'A state machine must have an initial state (`.initial`) and a dictionary of possible states (`.states`)',
      );
    });

    it('throws an error if the initial state is invalid', () => {
      expect(() => machine(unstartableDefinition)).toThrowError(
        `Cannot initialize the state machine to state '${STATE_IMPOSSIBLE}'. Is that one of the machine's defined states?`,
      );
    });

    it.each`
      partOfMachine | equals                               | description            | eqDescription
      ${'keys'}     | ${['is', 'send', 'value', 'states']} | ${'keys'}              | ${'the correct array'}
      ${'is'}       | ${expect.any(Function)}              | ${'`is` property'}     | ${'a function'}
      ${'send'}     | ${expect.any(Function)}              | ${'`send` property'}   | ${'a function'}
      ${'value'}    | ${definition.initial}                | ${'`value` property'}  | ${'the same as the `initial` value of the machine definition'}
      ${'states'}   | ${definition.states}                 | ${'`states` property'} | ${'the same as the `states` value of the machine definition'}
    `("The machine's $description should be $eqDescription", ({ partOfMachine, equals }) => {
      const test = partOfMachine === 'keys' ? Object.keys(liveMachine) : liveMachine[partOfMachine];

      expect(test).toEqual(equals);
    });

    it.each`
      initialState          | transitionEvent                 | expectedState
      ${definition.initial} | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
      ${STATE_LOADING}      | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
      ${STATE_ERRORED}      | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLE}
      ${STATE_IDLE}         | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
      ${STATE_LOADING}      | ${TRANSITION_LOAD_SUCCESS}      | ${STATE_IDLE}
    `(
      'properly steps from $initialState to $expectedState when the event "$transitionEvent" is sent',
      ({ initialState, transitionEvent, expectedState }) => {
        liveMachine.value = initialState;

        liveMachine.send(transitionEvent);

        expect(liveMachine.is(expectedState)).toBe(true);
        expect(liveMachine.value).toBe(expectedState);
      },
    );

    it.each`
      initialState     | transitionEvent
      ${STATE_IDLE}    | ${TRANSITION_ACKNOWLEDGE_ERROR}
      ${STATE_IDLE}    | ${TRANSITION_LOAD_SUCCESS}
      ${STATE_IDLE}    | ${TRANSITION_LOAD_ERROR}
      ${STATE_IDLE}    | ${'RANDOM_FOO'}
      ${STATE_LOADING} | ${TRANSITION_START_LOAD}
      ${STATE_LOADING} | ${TRANSITION_ACKNOWLEDGE_ERROR}
      ${STATE_LOADING} | ${'RANDOM_FOO'}
      ${STATE_ERRORED} | ${TRANSITION_LOAD_ERROR}
      ${STATE_ERRORED} | ${TRANSITION_LOAD_SUCCESS}
      ${STATE_ERRORED} | ${'RANDOM_FOO'}
    `(
      `does not perform any transition if the machine can't move from "$initialState" using the "$transitionEvent" event`,
      ({ initialState, transitionEvent }) => {
        liveMachine.value = initialState;

        liveMachine.send(transitionEvent);

        expect(liveMachine.is(initialState)).toBe(true);
        expect(liveMachine.value).toBe(initialState);
      },
    );

    describe('send', () => {
      it.each`
        startState       | transitionEvent                 | result
        ${STATE_IDLE}    | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
        ${STATE_LOADING} | ${TRANSITION_LOAD_SUCCESS}      | ${STATE_IDLE}
        ${STATE_LOADING} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
        ${STATE_ERRORED} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLE}
        ${STATE_ERRORED} | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
      `(
        'successfully transitions to $result from $startState when the transition $transitionEvent is received',
        ({ startState, transitionEvent, result }) => {
          liveMachine.value = startState;

          expect(liveMachine.send(transitionEvent)).toEqual(result);
        },
      );

      it.each`
        startState       | transitionEvent
        ${STATE_IDLE}    | ${TRANSITION_ACKNOWLEDGE_ERROR}
        ${STATE_IDLE}    | ${TRANSITION_LOAD_SUCCESS}
        ${STATE_IDLE}    | ${TRANSITION_LOAD_ERROR}
        ${STATE_IDLE}    | ${'RANDOM_FOO'}
        ${STATE_LOADING} | ${TRANSITION_START_LOAD}
        ${STATE_LOADING} | ${TRANSITION_ACKNOWLEDGE_ERROR}
        ${STATE_LOADING} | ${'RANDOM_FOO'}
        ${STATE_ERRORED} | ${TRANSITION_LOAD_ERROR}
        ${STATE_ERRORED} | ${TRANSITION_LOAD_SUCCESS}
        ${STATE_ERRORED} | ${'RANDOM_FOO'}
      `(
        'remains as $startState if an undefined transition ($transitionEvent) is received',
        ({ startState, transitionEvent }) => {
          liveMachine.value = startState;

          expect(liveMachine.send(transitionEvent)).toEqual(startState);
        },
      );

      describe('detached', () => {
        it.each`
          startState       | transitionEvent                 | result
          ${STATE_IDLE}    | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
          ${STATE_LOADING} | ${TRANSITION_LOAD_SUCCESS}      | ${STATE_IDLE}
          ${STATE_LOADING} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
          ${STATE_ERRORED} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLE}
          ${STATE_ERRORED} | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
        `(
          'successfully transitions to $result from $startState when the transition $transitionEvent is received outside the context of the machine',
          ({ startState, transitionEvent, result }) => {
            const liveSend = machine({
              ...definition,
              initial: startState,
            }).send;

            expect(liveSend(transitionEvent)).toEqual(result);
          },
        );

        it.each`
          startState       | transitionEvent
          ${STATE_IDLE}    | ${TRANSITION_ACKNOWLEDGE_ERROR}
          ${STATE_IDLE}    | ${TRANSITION_LOAD_SUCCESS}
          ${STATE_IDLE}    | ${TRANSITION_LOAD_ERROR}
          ${STATE_IDLE}    | ${'RANDOM_FOO'}
          ${STATE_LOADING} | ${TRANSITION_START_LOAD}
          ${STATE_LOADING} | ${TRANSITION_ACKNOWLEDGE_ERROR}
          ${STATE_LOADING} | ${'RANDOM_FOO'}
          ${STATE_ERRORED} | ${TRANSITION_LOAD_ERROR}
          ${STATE_ERRORED} | ${TRANSITION_LOAD_SUCCESS}
          ${STATE_ERRORED} | ${'RANDOM_FOO'}
        `(
          'remains as $startState if an undefined transition ($transitionEvent) is received',
          ({ startState, transitionEvent }) => {
            const liveSend = machine({
              ...definition,
              initial: startState,
            }).send;

            expect(liveSend(transitionEvent)).toEqual(startState);
          },
        );
      });
    });

    describe('is', () => {
      it.each`
        bool     | test             | actual
        ${true}  | ${STATE_IDLE}    | ${STATE_IDLE}
        ${false} | ${STATE_LOADING} | ${STATE_IDLE}
        ${false} | ${STATE_ERRORED} | ${STATE_IDLE}
        ${true}  | ${STATE_LOADING} | ${STATE_LOADING}
        ${false} | ${STATE_IDLE}    | ${STATE_LOADING}
        ${false} | ${STATE_ERRORED} | ${STATE_LOADING}
        ${true}  | ${STATE_ERRORED} | ${STATE_ERRORED}
        ${false} | ${STATE_IDLE}    | ${STATE_ERRORED}
        ${false} | ${STATE_LOADING} | ${STATE_ERRORED}
      `(
        'returns "$bool" for "$test" when the current state is "$actual"',
        ({ bool, test, actual }) => {
          liveMachine = machine({
            ...definition,
            initial: actual,
          });

          expect(liveMachine.is(test)).toEqual(bool);
        },
      );

      describe('detached', () => {
        it.each`
          bool     | test             | actual
          ${true}  | ${STATE_IDLE}    | ${STATE_IDLE}
          ${false} | ${STATE_LOADING} | ${STATE_IDLE}
          ${false} | ${STATE_ERRORED} | ${STATE_IDLE}
          ${true}  | ${STATE_LOADING} | ${STATE_LOADING}
          ${false} | ${STATE_IDLE}    | ${STATE_LOADING}
          ${false} | ${STATE_ERRORED} | ${STATE_LOADING}
          ${true}  | ${STATE_ERRORED} | ${STATE_ERRORED}
          ${false} | ${STATE_IDLE}    | ${STATE_ERRORED}
          ${false} | ${STATE_LOADING} | ${STATE_ERRORED}
        `(
          'returns "$bool" for "$test" when the current state is "$actual"',
          ({ bool, test, actual }) => {
            const liveIs = machine({
              ...definition,
              initial: actual,
            }).is;

            expect(liveIs(test)).toEqual(bool);
          },
        );
      });
    });
  });

  describe('transition', () => {
    it.each`
      startState       | transitionEvent                 | result
      ${STATE_IDLE}    | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
      ${STATE_LOADING} | ${TRANSITION_LOAD_SUCCESS}      | ${STATE_IDLE}
      ${STATE_LOADING} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
      ${STATE_ERRORED} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLE}
      ${STATE_ERRORED} | ${TRANSITION_START_LOAD}        | ${STATE_LOADING}
    `(
      'successfully transitions to $result from $startState when the transition $transitionEvent is received',
      ({ startState, transitionEvent, result }) => {
        expect(transition(definition, startState, transitionEvent)).toEqual(result);
      },
    );

    it.each`
      startState       | transitionEvent
      ${STATE_IDLE}    | ${TRANSITION_ACKNOWLEDGE_ERROR}
      ${STATE_IDLE}    | ${TRANSITION_LOAD_SUCCESS}
      ${STATE_IDLE}    | ${TRANSITION_LOAD_ERROR}
      ${STATE_IDLE}    | ${'RANDOM_FOO'}
      ${STATE_LOADING} | ${TRANSITION_START_LOAD}
      ${STATE_LOADING} | ${TRANSITION_ACKNOWLEDGE_ERROR}
      ${STATE_LOADING} | ${'RANDOM_FOO'}
      ${STATE_ERRORED} | ${TRANSITION_LOAD_ERROR}
      ${STATE_ERRORED} | ${TRANSITION_LOAD_SUCCESS}
      ${STATE_ERRORED} | ${'RANDOM_FOO'}
    `(
      'remains as $startState if an undefined transition ($transitionEvent) is received',
      ({ startState, transitionEvent }) => {
        expect(transition(definition, startState, transitionEvent)).toEqual(startState);
      },
    );

    it('remains as the provided starting state if it is an unrecognized state', () => {
      expect(transition(definition, 'RANDOM_FOO', TRANSITION_START_LOAD)).toEqual('RANDOM_FOO');
    });
  });
});
