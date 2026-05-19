import { s__ } from '~/locale';

const extractDisabled = (user) => {
  return Boolean(user?.duoStatus?.disabled ?? user?.disabled);
};

const extractDisabledReason = (user) => {
  return user?.duoStatus?.disabledReason ?? user?.disabledReason ?? user?.disabled_reason;
};

const extractFlowTriggerEvents = (user) => {
  return (
    user?.duoStatus?.flowTriggerEvents ?? user?.flowTriggerEvents ?? user?.flow_trigger_events ?? []
  );
};

const extractCompositeIdentityEnforced = (user) => {
  return user?.compositeIdentityEnforced ?? user?.composite_identity_enforced;
};

export const userIsAgent = (user) => {
  return Boolean(extractCompositeIdentityEnforced(user));
};

export const userHasFlowTriggerEvent = (user, eventType) => {
  const flowTriggerEvents = extractFlowTriggerEvents(user);

  return flowTriggerEvents.includes(eventType);
};

export const userDisabledReason = (user, eventType) => {
  const disabled = extractDisabled(user);
  const disabledReason = extractDisabledReason(user);
  const hasFlowTriggers = userHasFlowTriggerEvent(user, eventType);
  const isAgent = userIsAgent(user);

  if (disabled) {
    return disabledReason || s__('Agents|Cannot be assigned');
  }

  if (!isAgent) {
    return null;
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
