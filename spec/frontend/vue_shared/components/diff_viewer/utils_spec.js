import { transition } from '~/vue_shared/components/diff_viewer/utils';
import {
  TRANSITION_LOAD_START,
  TRANSITION_LOAD_ERROR,
  TRANSITION_LOAD_SUCCEED,
  TRANSITION_ACKNOWLEDGE_ERROR,
  STATE_IDLING,
  STATE_LOADING,
  STATE_ERRORED,
} from '~/diffs/constants';

describe('transition', () => {
  it.each`
    state        | transitionEvent                 | result
    ${'idle'}    | ${TRANSITION_LOAD_START}        | ${STATE_LOADING}
    ${'idle'}    | ${TRANSITION_LOAD_ERROR}        | ${STATE_IDLING}
    ${'idle'}    | ${TRANSITION_LOAD_SUCCEED}      | ${STATE_IDLING}
    ${'idle'}    | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLING}
    ${'loading'} | ${TRANSITION_LOAD_START}        | ${STATE_LOADING}
    ${'loading'} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
    ${'loading'} | ${TRANSITION_LOAD_SUCCEED}      | ${STATE_IDLING}
    ${'loading'} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_LOADING}
    ${'errored'} | ${TRANSITION_LOAD_START}        | ${STATE_LOADING}
    ${'errored'} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
    ${'errored'} | ${TRANSITION_LOAD_SUCCEED}      | ${STATE_ERRORED}
    ${'errored'} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLING}
  `(
    'correctly updates the state to "$result" when it starts as "$state" and the transition is "$transitionEvent"',
    ({ state, transitionEvent, result }) => {
      expect(transition(state, transitionEvent)).toBe(result);
    },
  );
});
