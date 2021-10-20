import { OBSTACLE_TYPES } from '~/vue_shared/components/user_deletion_obstacles/constants';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';

describe('parseUserDeletionObstacles', () => {
  const mockObstacles = [{ name: 'Obstacle' }];
  const expectedSchedule = { name: 'Obstacle', type: OBSTACLE_TYPES.oncallSchedules };
  const expectedPolicy = { name: 'Obstacle', type: OBSTACLE_TYPES.escalationPolicies };

  it('is undefined when user is not available', () => {
    expect(parseUserDeletionObstacles()).toHaveLength(0);
  });

  it('is empty when obstacles are not available for user', () => {
    expect(parseUserDeletionObstacles({})).toHaveLength(0);
  });

  it('is empty when user has no obstacles to deletion', () => {
    const input = { oncallSchedules: [], escalationPolicies: [] };

    expect(parseUserDeletionObstacles(input)).toHaveLength(0);
  });

  it('returns obstacles with type when user is part of on-call schedules', () => {
    const input = { oncallSchedules: mockObstacles, escalationPolicies: [] };
    const expectedOutput = [expectedSchedule];

    expect(parseUserDeletionObstacles(input)).toEqual(expectedOutput);
  });

  it('returns obstacles with type when user is part of escalation policies', () => {
    const input = { oncallSchedules: [], escalationPolicies: mockObstacles };
    const expectedOutput = [expectedPolicy];

    expect(parseUserDeletionObstacles(input)).toEqual(expectedOutput);
  });

  it('returns obstacles with type when user have every obstacle type', () => {
    const input = { oncallSchedules: mockObstacles, escalationPolicies: mockObstacles };
    const expectedOutput = [expectedSchedule, expectedPolicy];

    expect(parseUserDeletionObstacles(input)).toEqual(expectedOutput);
  });
});
