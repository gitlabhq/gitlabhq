import { escape } from 'lodash';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { __, sprintf } from '~/locale';

export const UNEXPECTED_ERROR_CONFIG = __(
  'An unexpected error occurred while checking the project environment.',
);
export const UNEXPECTED_ERROR_RUNNERS = __(
  'An unexpected error occurred while checking the project runners.',
);
export const UNEXPECTED_ERROR_STATUS = __(
  'An unexpected error occurred while communicating with the Web Terminal.',
);
export const UNEXPECTED_ERROR_STARTING = __(
  'An unexpected error occurred while starting the Web Terminal.',
);
export const UNEXPECTED_ERROR_STOPPING = __(
  'An unexpected error occurred while stopping the Web Terminal.',
);
export const EMPTY_RUNNERS = __(
  'Configure GitLab runners to start using the Web Terminal. %{helpStart}Learn more.%{helpEnd}',
);
export const ERROR_CONFIG = __(
  'Configure a %{codeStart}.gitlab-webide.yml%{codeEnd} file in the %{codeStart}.gitlab%{codeEnd} directory to start using the Web Terminal. %{helpStart}Learn more.%{helpEnd}',
);
export const ERROR_PERMISSION = __(
  'You do not have permission to run the Web Terminal. Please contact a project administrator.',
);

export const configCheckError = (status, helpUrl) => {
  if (status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
    return sprintf(
      ERROR_CONFIG,
      {
        helpStart: `<a href="${escape(helpUrl)}" target="_blank">`,
        helpEnd: '</a>',
        codeStart: '<code>',
        codeEnd: '</code>',
      },
      false,
    );
  }
  if (status === HTTP_STATUS_FORBIDDEN) {
    return ERROR_PERMISSION;
  }

  return UNEXPECTED_ERROR_CONFIG;
};

export const runnersCheckEmpty = (helpUrl) =>
  sprintf(
    EMPTY_RUNNERS,
    {
      helpStart: `<a href="${escape(helpUrl)}" target="_blank">`,
      helpEnd: '</a>',
    },
    false,
  );
