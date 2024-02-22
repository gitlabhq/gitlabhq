import { __ } from '~/locale';

export const restrictedVisibilityLevelsMessage = ({
  availableVisibilityLevels,
  restrictedVisibilityLevels,
}) => {
  if (!restrictedVisibilityLevels.length) {
    return '';
  }

  if (!availableVisibilityLevels.length) {
    return __('Visibility settings have been disabled by the administrator.');
  }

  return __('Other visibility settings have been disabled by the administrator.');
};
