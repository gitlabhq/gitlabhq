import { s__ } from '~/locale';

export const userIsAgent = (user) => {
  return Boolean(user?.compositeIdentityEnforced);
};

export const userHasFlowTriggerEvent = (user, eventType) => {
  const flowTriggerEvents = user?.duoStatus?.flowTriggerEvents ?? [];

  return flowTriggerEvents.includes(eventType);
};

export const userDisabledReason = (user, eventType) => {
  const disabled = Boolean(user?.duoStatus?.disabled);
  const disabledReason = user?.duoStatus?.disabledReason;
  const hasFlowTriggers = userHasFlowTriggerEvent(user, eventType);
  const isAgent = userIsAgent(user);

  if (!isAgent) {
    return null;
  }

  if (disabled) {
    return disabledReason || s__('Agents|Cannot be assigned');
  }

  if (!hasFlowTriggers) {
    return s__('Agents|No triggers for this event');
  }

  return null;
};

export const userIsDisabled = (user, eventType) => {
  return Boolean(userDisabledReason(user, eventType));
};

export const userDisabledAttributes = (user, eventType) => {
  const reason = userDisabledReason(user, eventType);

  if (reason) {
    return {
      isDisabled: true,
      disabledReason: reason,
    };
  }

  return {
    isDisabled: false,
  };
};
