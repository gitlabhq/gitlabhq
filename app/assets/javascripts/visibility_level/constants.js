export const VISIBILITY_LEVEL_PRIVATE = 'private';
export const VISIBILITY_LEVEL_INTERNAL = 'internal';
export const VISIBILITY_LEVEL_PUBLIC = 'public';

// Matches `lib/gitlab/visibility_level.rb`
export const VISIBILITY_LEVELS_ENUM = {
  [VISIBILITY_LEVEL_PRIVATE]: 0,
  [VISIBILITY_LEVEL_INTERNAL]: 10,
  [VISIBILITY_LEVEL_PUBLIC]: 20,
};
