import { __ } from '~/locale';

export const visibilityOptions = {
  PRIVATE: 0,
  INTERNAL: 10,
  PUBLIC: 20,
};

export const visibilityLevelDescriptions = {
  [visibilityOptions.PRIVATE]: __(
    'The project is accessible only by members of the project. Access must be granted explicitly to each user.',
  ),
  [visibilityOptions.INTERNAL]: __('The project can be accessed by any user who is logged in.'),
  [visibilityOptions.PUBLIC]: __(
    'The project can be accessed by anyone, regardless of authentication.',
  ),
};
