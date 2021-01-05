import { __ } from '~/locale';

// These statuses are based on how the backend defines pod phases here
// lib/gitlab/kubernetes/pod.rb

export const STATUS_MAP = {
  succeeded: {
    class: 'succeeded',
    text: __('Succeeded'),
    stable: true,
  },
  running: {
    class: 'running',
    text: __('Running'),
    stable: true,
  },
  failed: {
    class: 'failed',
    text: __('Failed'),
    stable: true,
  },
  pending: {
    class: 'pending',
    text: __('Pending'),
    stable: true,
  },
  unknown: {
    class: 'unknown',
    text: __('Unknown'),
    stable: true,
  },
};

export const CANARY_STATUS = {
  class: 'canary-icon',
  text: __('Canary'),
  stable: false,
};

export const CANARY_UPDATE_MODAL = 'confirm-canary-change';
