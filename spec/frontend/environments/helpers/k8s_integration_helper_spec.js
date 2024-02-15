import {
  humanizeClusterErrors,
  createK8sAccessConfiguration,
} from '~/environments/helpers/k8s_integration_helper';
import { CLUSTER_AGENT_ERROR_MESSAGES } from '~/environments/constants';

jest.mock('~/lib/utils/csrf', () => ({ headers: { token: 'mock-csrf-token' } }));

describe('k8s_integration_helper', () => {
  describe('humanizeClusterErrors', () => {
    it.each(['unauthorized', 'forbidden', 'not found', 'other'])(
      'returns correct object of statuses when error reason is %s',
      (reason) => {
        expect(humanizeClusterErrors(reason)).toEqual(CLUSTER_AGENT_ERROR_MESSAGES[reason]);
      },
    );
  });

  describe('createK8sAccessConfiguration', () => {
    const kasTunnelUrl = '//kas-tunnel-url';
    const gitlabAgentId = 1;

    const subject = createK8sAccessConfiguration({ kasTunnelUrl, gitlabAgentId });

    it('receives kasTunnelUrl and sets it as a basePath', () => {
      expect(subject).toMatchObject({
        basePath: kasTunnelUrl,
      });
    });

    it('receives gitlabAgentId and sets it as part of headers', () => {
      expect(subject.headers).toMatchObject({
        'GitLab-Agent-Id': gitlabAgentId,
      });
    });

    it('provides csrf headers into headers', () => {
      expect(subject.headers).toMatchObject({
        token: 'mock-csrf-token',
      });
    });

    it('provides proper content type to the headers', () => {
      expect(subject.headers).toMatchObject({
        'Content-Type': 'application/json',
        Accept: 'application/json',
      });
    });

    it('includes credentials', () => {
      expect(subject).toMatchObject({
        credentials: 'include',
      });
    });
  });
});
