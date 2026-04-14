import {
  userIsAgent,
  userHasFlowTriggerEvent,
  userDisabledReason,
  userIsDisabled,
  userDisabledAttributes,
} from '~/ai/agents_utils';
import { FLOW_TRIGGER_EVENTS } from '~/vue_shared/constants';

describe('Agents utils', () => {
  const undefinedUser = null;
  const unknownUser = {};
  const humanUser = {
    compositeIdentityEnforced: false,
  };
  const disabledAgentUserWithReason = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: true,
      disabledReason: 'User is disabled',
    },
  };
  const disabledAgentUserWithoutReason = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: true,
      disabledReason: null,
    },
  };
  const assignAgentUser = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: false,
      flowTriggerEvents: [FLOW_TRIGGER_EVENTS.ASSIGN],
    },
  };
  const triggerlessAgentUser = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: false,
      flowTriggerEvents: [],
    },
  };

  describe('userIsAgent', () => {
    describe('when compositeIdentityEnforced is set to true', () => {
      it('returns true', () => {
        expect(userIsAgent(disabledAgentUserWithReason)).toBe(true);
      });
    });

    describe('when compositeIdentityEnforced is set to false', () => {
      it('returns false', () => {
        expect(userIsAgent(humanUser)).toBe(false);
      });
    });

    describe('when user has compositeIdentityEnforced is not set', () => {
      it('returns false', () => {
        expect(userIsAgent(unknownUser)).toBe(false);
      });
    });

    describe('when user is not defined', () => {
      it('returns false', () => {
        expect(userIsAgent(undefinedUser)).toBe(false);
      });
    });
  });

  describe('userHasFlowTriggerEvent', () => {
    describe('when duoStatus is not set', () => {
      it('returns false', () => {
        expect(userHasFlowTriggerEvent(unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN_REVIEWER)).toBe(
          false,
        );
        expect(userHasFlowTriggerEvent(undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN_REVIEWER)).toBe(
          false,
        );
        expect(
          userHasFlowTriggerEvent(triggerlessAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN_REVIEWER),
        ).toBe(false);
      });
    });

    describe('when duoStatus.flowTriggerEvents is not set', () => {
      it('returns false', () => {
        expect(
          userHasFlowTriggerEvent(disabledAgentUserWithReason, FLOW_TRIGGER_EVENTS.ASSIGN_REVIEWER),
        ).toBe(false);
      });
    });

    describe('when duoStatus.flowTriggerEvents does not contain the event type being tested', () => {
      it('returns false', () => {
        expect(userHasFlowTriggerEvent(assignAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN_REVIEWER)).toBe(
          false,
        );
      });
    });

    describe('when duoStatus.flowTriggerEvents contains the event type being tested', () => {
      it('returns true', () => {
        expect(userHasFlowTriggerEvent(assignAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(true);
      });
    });
  });

  describe('userDisabledReason', () => {
    describe('when user is not an agent', () => {
      it('returns null', () => {
        expect(userDisabledReason(undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(null);
        expect(userDisabledReason(unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(null);
        expect(userDisabledReason(humanUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(null);
      });
    });

    describe('when user is disabled', () => {
      describe('with a reason', () => {
        it('returns that reason', () => {
          expect(userDisabledReason(disabledAgentUserWithReason, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(
            disabledAgentUserWithReason.duoStatus.disabledReason,
          );
        });
      });

      describe('without a reason', () => {
        it('returns a default generic reason', () => {
          expect(
            userDisabledReason(disabledAgentUserWithoutReason, FLOW_TRIGGER_EVENTS.ASSIGN),
          ).toBe('Cannot be assigned');
        });
      });
    });

    describe('when user is not disabled', () => {
      describe('and does not have a flow trigger for that event type', () => {
        it('returns no triggers for the event message', () => {
          expect(userDisabledReason(triggerlessAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(
            'No triggers for this event',
          );
        });
      });

      describe('and has flow trigger for that event type', () => {
        it('returns null', () => {
          expect(userDisabledReason(assignAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(null);
        });
      });
    });
  });

  describe('userIsDisabled', () => {
    describe('when user is not an agent', () => {
      it('returns false', () => {
        expect(userIsDisabled(undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(false);
        expect(userIsDisabled(unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(false);
        expect(userIsDisabled(humanUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(false);
      });
    });

    describe('when user is disabled', () => {
      it('returns true', () => {
        expect(userIsDisabled(disabledAgentUserWithReason, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(true);
        expect(userIsDisabled(disabledAgentUserWithoutReason, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(
          true,
        );
      });
    });

    describe('when user is not disabled', () => {
      describe('and does not have a flow trigger for that event type', () => {
        it('returns true', () => {
          expect(userIsDisabled(triggerlessAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(true);
        });
      });

      describe('and has flow trigger for that event type', () => {
        it('returns false', () => {
          expect(userIsDisabled(assignAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toBe(false);
        });
      });
    });
  });

  describe('userDisabledAttributes', () => {
    describe('when user is not an agent', () => {
      it('returns object with isDisabled false', () => {
        const expectedResult = {
          isDisabled: false,
        };

        expect(userDisabledAttributes(undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toEqual(
          expectedResult,
        );
        expect(userDisabledAttributes(unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toEqual(
          expectedResult,
        );
        expect(userDisabledAttributes(humanUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toEqual(
          expectedResult,
        );
      });
    });

    describe('when user is disabled', () => {
      describe('with a reason', () => {
        it('returns object with that reason', () => {
          expect(
            userDisabledAttributes(disabledAgentUserWithReason, FLOW_TRIGGER_EVENTS.ASSIGN),
          ).toEqual({
            isDisabled: true,
            disabledReason: disabledAgentUserWithReason.duoStatus.disabledReason,
          });
        });
      });

      describe('without a reason', () => {
        it('returns object with a default generic reason', () => {
          expect(
            userDisabledAttributes(disabledAgentUserWithoutReason, FLOW_TRIGGER_EVENTS.ASSIGN),
          ).toEqual({
            isDisabled: true,
            disabledReason: 'Cannot be assigned',
          });
        });
      });
    });

    describe('when user is not disabled', () => {
      describe('and does not have a flow trigger for that event type', () => {
        it('returns no triggers for the event message', () => {
          expect(userDisabledAttributes(triggerlessAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toEqual({
            isDisabled: true,
            disabledReason: 'No triggers for this event',
          });
        });
      });

      describe('and has flow trigger for that event type', () => {
        it('returns object with isDisabled false', () => {
          expect(userDisabledAttributes(assignAgentUser, FLOW_TRIGGER_EVENTS.ASSIGN)).toEqual({
            isDisabled: false,
          });
        });
      });
    });
  });
});
