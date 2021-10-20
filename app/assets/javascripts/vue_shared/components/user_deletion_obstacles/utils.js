import { OBSTACLE_TYPES } from './constants';

const addTypeToObstacles = (obstacles, type) => {
  if (!obstacles) return [];

  return obstacles?.map((obstacle) => ({ type, ...obstacle }));
};

// For use with user objects formatted via internal REST API.
// If the removal/deletion of a user could cause critical
// problems, return a single array containing all affected
// associations including their type.
export const parseUserDeletionObstacles = (user) => {
  if (!user) return [];

  return Object.keys(OBSTACLE_TYPES).flatMap((type) => {
    return addTypeToObstacles(user[type], OBSTACLE_TYPES[type]);
  });
};
