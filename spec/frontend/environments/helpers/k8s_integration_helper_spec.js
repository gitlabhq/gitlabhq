import { humanizeClusterErrors } from '~/environments/helpers/k8s_integration_helper';

import { CLUSTER_AGENT_ERROR_MESSAGES } from '~/environments/constants';

describe('k8s_integration_helper', () => {
  describe('humanizeClusterErrors', () => {
    it.each(['unauthorized', 'forbidden', 'not found', 'other'])(
      'returns correct object of statuses when error reason is %s',
      (reason) => {
        expect(humanizeClusterErrors(reason)).toEqual(CLUSTER_AGENT_ERROR_MESSAGES[reason]);
      },
    );
  });
});
