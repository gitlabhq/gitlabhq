export const BROADCAST_CHANNEL_SESSION_EXPIRY = 'session-expiry-notifications';
export const BROADCAST_CHANNEL_SAML_SESSION_EXPIRY = 'saml-session-expiry-notifications';
// Signals that the general session-expiry modal is displaying, so subordinate modals
// (the group-SAML reload modal) yield instead of stacking on top of it.
export const BROADCAST_CHANNEL_SESSION_EXPIRE_MODAL_SHOWN = 'session-expire-modal-shown';
export const INTERVAL_SESSION_MODAL = 1 * 1000;
