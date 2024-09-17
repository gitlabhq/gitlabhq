import { __, s__ } from '~/locale';

export const VISIBILITY_LEVEL_PRIVATE_STRING = 'private';
export const VISIBILITY_LEVEL_INTERNAL_STRING = 'internal';
export const VISIBILITY_LEVEL_PUBLIC_STRING = 'public';

export const VISIBILITY_LEVEL_PRIVATE_INTEGER = 0;
export const VISIBILITY_LEVEL_INTERNAL_INTEGER = 10;
export const VISIBILITY_LEVEL_PUBLIC_INTEGER = 20;

// Matches `lib/gitlab/visibility_level.rb`
export const VISIBILITY_LEVELS_STRING_TO_INTEGER = {
  [VISIBILITY_LEVEL_PRIVATE_STRING]: VISIBILITY_LEVEL_PRIVATE_INTEGER,
  [VISIBILITY_LEVEL_INTERNAL_STRING]: VISIBILITY_LEVEL_INTERNAL_INTEGER,
  [VISIBILITY_LEVEL_PUBLIC_STRING]: VISIBILITY_LEVEL_PUBLIC_INTEGER,
};

export const VISIBILITY_LEVELS_INTEGER_TO_STRING = {
  [VISIBILITY_LEVEL_PRIVATE_INTEGER]: VISIBILITY_LEVEL_PRIVATE_STRING,
  [VISIBILITY_LEVEL_INTERNAL_INTEGER]: VISIBILITY_LEVEL_INTERNAL_STRING,
  [VISIBILITY_LEVEL_PUBLIC_INTEGER]: VISIBILITY_LEVEL_PUBLIC_STRING,
};

export const GROUP_VISIBILITY_TYPE = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: __(
    'Public - The group and any public projects can be viewed without any authentication.',
  ),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: __(
    'Internal - The group and any internal projects can be viewed by any logged in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: __(
    'Private - The group and its projects can only be viewed by members.',
  ),
};

export const PROJECT_VISIBILITY_TYPE = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: __(
    'Public - The project can be accessed without any authentication.',
  ),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: __(
    'Internal - The project can be accessed by any logged in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: __(
    'Private - Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
  ),
};

export const ORGANIZATION_VISIBILITY_TYPE = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: s__(
    'Organization|Public - The organization can be accessed without any authentication.',
  ),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: s__(
    'Organization|Internal - The organization can be accessed by any signed in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: s__(
    'Organization|Private - The organization can only be viewed by members.',
  ),
};

export const GROUP_VISIBILITY_LEVEL_DESCRIPTIONS = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: s__(
    'VisibilityLevel|The group and any public projects can be viewed without any authentication.',
  ),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: s__(
    'VisibilityLevel|The group and any internal projects can be viewed by any logged in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: s__(
    'VisibilityLevel|The group and its projects can only be viewed by members.',
  ),
};

export const ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: s__('Organization|Accessible without any authentication.'),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: s__(
    'Organization|Accessible by any signed in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: s__('Organization|Only accessible by organization members.'),
};

export const VISIBILITY_LEVEL_LABELS = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: s__('VisibilityLevel|Public'),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: s__('VisibilityLevel|Internal'),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: s__('VisibilityLevel|Private'),
};

export const VISIBILITY_TYPE_ICON = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: 'earth',
  [VISIBILITY_LEVEL_INTERNAL_STRING]: 'shield',
  [VISIBILITY_LEVEL_PRIVATE_STRING]: 'lock',
};
