import { snakeCase } from 'lodash';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';

export const handleTracking = ({ name, data }) => {
  const snakeCaseEventName = snakeCase(name);

  if (data && Object.keys(data).length) {
    Tracking.event(undefined, snakeCaseEventName, {
      /* See GitLab snowplow schema for a definition of the extra field
       * https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_standard/jsonschema/1-1-0.
       */
      extra: convertObjectPropsToSnakeCase(data, {
        deep: true,
      }),
    });
  } else {
    Tracking.event(undefined, snakeCaseEventName);
  }
};
