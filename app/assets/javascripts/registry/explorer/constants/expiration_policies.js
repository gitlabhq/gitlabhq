import { s__ } from '~/locale';

export const EXPIRATION_POLICY_WILL_RUN_IN = s__(
  'ContainerRegistry|Expiration policy will run in %{time}',
);
export const EXPIRATION_POLICY_DISABLED_TEXT = s__(
  'ContainerRegistry|Expiration policy is disabled',
);
export const EXPIRATION_POLICY_DISABLED_MESSAGE = s__(
  'ContainerRegistry|Expiration policies help manage the storage space used by the Container Registry, but the expiration policies for this registry are disabled. Contact your administrator to enable. %{docLinkStart}More information%{docLinkEnd}',
);
