import {
  userIsAgent,
  userHasFlowTriggerEvent,
  userDisabledReason,
  userIsDisabled,
  userDisabledAttributes,
} from '~/ai/agents_utils';
import { FLOW_TRIGGER_EVENTS } from '~/vue_shared/constants';

describe('Agents utils', () => {
  const noTriggersForThisEventMessage = 'No triggers for this event';
  const cannotBeAssignedMessage = 'Cannot be assigned';

  // non-agent users
  const undefinedUser = null;
  const unknownUser = {};

  // human users
  const humanUser = {
    compositeIdentityEnforced: false,
  };
  const disabledHumanUserWithReason = {
    compositeIdentityEnforced: false,
    disabled: true,
    disabledReason: 'User is disabled',
  };
  const disabledHumanUserWithNoReason = {
    compositeIdentityEnforced: false,
    disabled: true,
    disabledReason: null,
  };

  // agents with duoStatus attributes
  const agentWithDuoStatus = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: false,
      flowTriggerEvents: [],
    },
  };
  const agentWithDuoStatusAndAssignTrigger = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: false,
      flowTriggerEvents: [FLOW_TRIGGER_EVENTS.ASSIGN],
    },
  };
  const disabledAgentWithDuoStatusAndReason = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: true,
      disabledReason: 'User is disabled',
    },
  };
  const disabledAgentWithDuoStatusAndNoReason = {
    compositeIdentityEnforced: true,
    duoStatus: {
      disabled: true,
      disabledReason: null,
    },
  };

  // agents with flat snake_case attributes
  const agentWithSnakeCase = {
    composite_identity_enforced: true,
    disabled: false,
    flow_trigger_events: [],
  };
  const agentWithSnakeCaseAndAssignTrigger = {
    composite_identity_enforced: true,
    disabled: false,
    flow_trigger_events: [FLOW_TRIGGER_EVENTS.ASSIGN],
  };
  const disabledAgentWithSnakeCaseAndReason = {
    composite_identity_enforced: true,
    disabled: true,
    disabled_reason: 'User is disabled',
  };
  const disabledAgentWithSnakeCaseAndNoReason = {
    composite_identity_enforced: true,
    disabled: true,
    disabled_reason: null,
  };

  // agents with flat camelCase attributes
  const agentWithCamelCase = {
    compositeIdentityEnforced: true,
    disabled: false,
    flowTriggerEvents: [],
  };
  const agentWithCamelCaseAndAssignTrigger = {
    compositeIdentityEnforced: true,
    disabled: false,
    flowTriggerEvents: [FLOW_TRIGGER_EVENTS.ASSIGN],
  };
  const disabledAgentWithCamelCaseAndReason = {
    compositeIdentityEnforced: true,
    disabled: true,
    disabledReason: 'User is disabled',
  };
  const disabledAgentWithCamelCaseAndNoReason = {
    compositeIdentityEnforced: true,
    disabled: true,
    disabledReason: null,
  };

  describe('userIsAgent', () => {
    it.each([
      [undefinedUser, false],
      [unknownUser, false],
      [humanUser, false],
      [agentWithDuoStatus, true],
      [agentWithCamelCase, true],
      [agentWithSnakeCase, true],
    ])('with %s returns %s', (user, expected) => {
      expect(userIsAgent(user)).toBe(expected);
    });
  });

  describe('userHasFlowTriggerEvent', () => {
    it.each([
      [undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [humanUser, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [agentWithDuoStatusAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [agentWithCamelCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [agentWithSnakeCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [agentWithDuoStatusAndAssignTrigger, FLOW_TRIGGER_EVENTS.MENTION, false],
      [agentWithCamelCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.MENTION, false],
      [agentWithSnakeCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.MENTION, false],
    ])('with %s returns %s', (user, trigger, expected) => {
      expect(userHasFlowTriggerEvent(user, trigger)).toBe(expected);
    });
  });

  describe('userDisabledReason', () => {
    it.each([
      [undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN, null],
      [unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN, null],
      [humanUser, FLOW_TRIGGER_EVENTS.ASSIGN, null],
      [agentWithDuoStatusAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, null],
      [agentWithCamelCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, null],
      [agentWithSnakeCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, null],
      [disabledAgentWithDuoStatusAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, cannotBeAssignedMessage],
      [disabledAgentWithSnakeCaseAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, cannotBeAssignedMessage],
      [disabledAgentWithCamelCaseAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, cannotBeAssignedMessage],
      [disabledHumanUserWithNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, cannotBeAssignedMessage],
      [
        disabledHumanUserWithReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        disabledHumanUserWithReason.disabledReason,
      ],
      [
        agentWithDuoStatusAndAssignTrigger,
        FLOW_TRIGGER_EVENTS.MENTION,
        noTriggersForThisEventMessage,
      ],
      [
        agentWithCamelCaseAndAssignTrigger,
        FLOW_TRIGGER_EVENTS.MENTION,
        noTriggersForThisEventMessage,
      ],
      [
        agentWithSnakeCaseAndAssignTrigger,
        FLOW_TRIGGER_EVENTS.MENTION,
        noTriggersForThisEventMessage,
      ],
      [
        disabledAgentWithDuoStatusAndReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        disabledAgentWithDuoStatusAndReason.duoStatus.disabledReason,
      ],
      [
        disabledAgentWithSnakeCaseAndReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        disabledAgentWithSnakeCaseAndReason.disabled_reason,
      ],
      [
        disabledAgentWithCamelCaseAndReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        disabledAgentWithCamelCaseAndReason.disabledReason,
      ],
    ])('with %s returns %s', (user, trigger, expected) => {
      expect(userDisabledReason(user, trigger)).toBe(expected);
    });
  });

  describe('userIsDisabled', () => {
    it.each([
      [undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [humanUser, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [disabledHumanUserWithReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [agentWithDuoStatusAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [agentWithCamelCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [agentWithSnakeCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, false],
      [disabledAgentWithDuoStatusAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [disabledAgentWithSnakeCaseAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [disabledAgentWithCamelCaseAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [agentWithDuoStatusAndAssignTrigger, FLOW_TRIGGER_EVENTS.MENTION, true],
      [agentWithCamelCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.MENTION, true],
      [agentWithSnakeCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.MENTION, true],
      [disabledAgentWithDuoStatusAndReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [disabledAgentWithSnakeCaseAndReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
      [disabledAgentWithCamelCaseAndReason, FLOW_TRIGGER_EVENTS.ASSIGN, true],
    ])('with %s returns %s', (user, trigger, expected) => {
      expect(userIsDisabled(user, trigger)).toBe(expected);
    });
  });

  describe('userDisabledAttributes', () => {
    const disabled = {
      isDisabled: true,
    };
    const notDisabled = {
      isDisabled: false,
    };
    const disabledWithNoReason = {
      ...disabled,
      disabledReason: cannotBeAssignedMessage,
    };

    it.each([
      [undefinedUser, FLOW_TRIGGER_EVENTS.ASSIGN, notDisabled],
      [unknownUser, FLOW_TRIGGER_EVENTS.ASSIGN, notDisabled],
      [humanUser, FLOW_TRIGGER_EVENTS.ASSIGN, notDisabled],
      [agentWithDuoStatusAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, notDisabled],
      [agentWithCamelCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, notDisabled],
      [agentWithSnakeCaseAndAssignTrigger, FLOW_TRIGGER_EVENTS.ASSIGN, notDisabled],
      [disabledAgentWithDuoStatusAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, disabledWithNoReason],
      [disabledAgentWithSnakeCaseAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, disabledWithNoReason],
      [disabledAgentWithCamelCaseAndNoReason, FLOW_TRIGGER_EVENTS.ASSIGN, disabledWithNoReason],
      [
        disabledHumanUserWithReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        { ...disabled, disabledReason: disabledHumanUserWithReason.disabledReason },
      ],
      [
        disabledAgentWithDuoStatusAndReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        {
          ...disabled,
          disabledReason: disabledAgentWithDuoStatusAndReason.duoStatus.disabledReason,
        },
      ],
      [
        disabledAgentWithSnakeCaseAndReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        { ...disabled, disabledReason: disabledAgentWithSnakeCaseAndReason.disabled_reason },
      ],
      [
        disabledAgentWithCamelCaseAndReason,
        FLOW_TRIGGER_EVENTS.ASSIGN,
        { ...disabled, disabledReason: disabledAgentWithCamelCaseAndReason.disabledReason },
      ],
      [
        agentWithDuoStatusAndAssignTrigger,
        FLOW_TRIGGER_EVENTS.MENTION,
        { ...disabled, disabledReason: noTriggersForThisEventMessage },
      ],
      [
        agentWithCamelCaseAndAssignTrigger,
        FLOW_TRIGGER_EVENTS.MENTION,
        { ...disabled, disabledReason: noTriggersForThisEventMessage },
      ],
      [
        agentWithSnakeCaseAndAssignTrigger,
        FLOW_TRIGGER_EVENTS.MENTION,
        { ...disabled, disabledReason: noTriggersForThisEventMessage },
      ],
    ])('with %s returns %s', (user, trigger, expected) => {
      expect(userDisabledAttributes(user, trigger)).toEqual(expected);
    });
  });
});
