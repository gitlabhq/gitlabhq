import {
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import { buildRedirectConfig } from '~/groups_projects/actions';

describe('buildRedirectConfig', () => {
  const path = '/dashboard/projects';
  const deleteScheduledMessage = 'Test Project moved to pending deletion.';
  const deleteMessage = 'Test Project is being deleted.';
  const leaveMessage = 'You left the "Test Project" project.';

  it('returns configuration object with DELETE, DELETE_IMMEDIATELY, and LEAVE actions', () => {
    const config = buildRedirectConfig({
      path,
      deleteScheduledMessage,
      deleteMessage,
      leaveMessage,
    });

    expect(config).toHaveProperty(ACTION_DELETE);
    expect(config).toHaveProperty(ACTION_DELETE_IMMEDIATELY);
    expect(config).toHaveProperty(ACTION_LEAVE);
  });

  it('configures ACTION_DELETE action with correct path and alerts', () => {
    const config = buildRedirectConfig({
      path,
      deleteScheduledMessage,
      deleteMessage,
      leaveMessage,
    });

    expect(config[ACTION_DELETE]).toEqual({
      path,
      alerts: [
        {
          id: 'namespace-delete-scheduled-success',
          message: deleteScheduledMessage,
          variant: 'info',
        },
      ],
    });
  });

  it('configures ACTION_DELETE_IMMEDIATELY action with correct path and alerts', () => {
    const config = buildRedirectConfig({
      path,
      deleteScheduledMessage,
      deleteMessage,
      leaveMessage,
    });

    expect(config[ACTION_DELETE_IMMEDIATELY]).toEqual({
      path,
      alerts: [
        {
          id: 'namespace-delete-success',
          message: deleteMessage,
          variant: 'info',
        },
      ],
    });
  });

  it('configures LEAVE action with correct path and alerts', () => {
    const config = buildRedirectConfig({
      path,
      deleteScheduledMessage,
      deleteMessage,
      leaveMessage,
    });

    expect(config[ACTION_LEAVE]).toEqual({
      path,
      alerts: [
        {
          id: 'namespace-leave-success',
          message: leaveMessage,
          variant: 'info',
        },
      ],
    });
  });
});
