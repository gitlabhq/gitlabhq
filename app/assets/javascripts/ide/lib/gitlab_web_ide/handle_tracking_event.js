import { snakeCase } from 'lodash';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';

export const handleTracking = ({ name, data }) => {
  const snakeCaseEventName = snakeCase(name);

  if (data && Object.keys(data).length) {
    Tracking.event(undefined, snakeCaseEventName, {
      /* See GitLab snowplow schema for a definition of the extra field
       * https://docs.gitlab.com/ee/development/snowplow/schemas.html#gitlab_standard.
       */
      extra: convertObjectPropsToSnakeCase(data, {
        deep: true,
      }),
    });
  } else {
    Tracking.event(undefined, snakeCaseEventName);
  }
};
