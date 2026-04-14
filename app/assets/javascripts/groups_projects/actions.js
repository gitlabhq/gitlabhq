import {
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';

export function buildRedirectConfig({ path, deleteMessage, deleteScheduledMessage, leaveMessage }) {
  return {
    [ACTION_DELETE]: {
      path,
      alerts: [
        {
          id: 'namespace-delete-scheduled-success',
          message: deleteScheduledMessage,
          variant: 'info',
        },
      ],
    },
    [ACTION_DELETE_IMMEDIATELY]: {
      path,
      alerts: [
        {
          id: 'namespace-delete-success',
          message: deleteMessage,
          variant: 'info',
        },
      ],
    },
    [ACTION_LEAVE]: {
      path,
      alerts: [
        {
          id: 'namespace-leave-success',
          message: leaveMessage,
          variant: 'info',
        },
      ],
    },
  };
}
