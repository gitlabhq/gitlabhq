import { RENAMED_DIFF_TRANSITIONS } from '~/diffs/constants';

export const transition = (currentState, transitionEvent) => {
  const key = `${currentState}:${transitionEvent}`;

  if (RENAMED_DIFF_TRANSITIONS[key]) {
    return RENAMED_DIFF_TRANSITIONS[key];
  }

  return currentState;
};
