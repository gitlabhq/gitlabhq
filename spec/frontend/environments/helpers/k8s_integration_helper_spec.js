import {
  humanizeClusterErrors,
  createK8sAccessConfiguration,
  fluxSyncStatus,
  updateFluxRequested,
} from '~/environments/helpers/k8s_integration_helper';
import {
  CLUSTER_AGENT_ERROR_MESSAGES,
  STATUS_TRUE,
  STATUS_FALSE,
  STATUS_UNKNOWN,
  REASON_PROGRESSING,
} from '~/environments/constants';

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

  describe('fluxSyncStatus', () => {
    const message = 'message from Flux';
    let fluxConditions;

    it.each`
      status            | type             | reason                | statusText                    | statusMessage
      ${STATUS_TRUE}    | ${'Stalled'}     | ${''}                 | ${'stalled'}                  | ${{ message }}
      ${STATUS_TRUE}    | ${'Reconciling'} | ${''}                 | ${'reconciling'}              | ${''}
      ${STATUS_UNKNOWN} | ${'Ready'}       | ${REASON_PROGRESSING} | ${'reconcilingWithBadConfig'} | ${{ message }}
      ${STATUS_TRUE}    | ${'Ready'}       | ${''}                 | ${'reconciled'}               | ${''}
      ${STATUS_FALSE}   | ${'Ready'}       | ${''}                 | ${'failed'}                   | ${{ message }}
      ${STATUS_UNKNOWN} | ${'Ready'}       | ${''}                 | ${'unknown'}                  | ${''}
    `(
      'renders sync status as $statusText when status is $status, type is $type, and reason is $reason',
      ({ status, type, reason, statusText, statusMessage }) => {
        fluxConditions = [
          {
            status,
            type,
            reason,
            message,
          },
        ];

        expect(fluxSyncStatus(fluxConditions)).toMatchObject({
          status: statusText,
          ...statusMessage,
        });
      },
    );
  });

  describe('updateFluxRequested', () => {
    it('provides JSON with the current date for updating the `requestedAt` field', () => {
      const now = new Date();

      expect(updateFluxRequested()).toEqual(
        JSON.stringify([
          {
            op: 'replace',
            path: '/metadata/annotations/reconcile.fluxcd.io~1requestedAt',
            value: now,
          },
        ]),
      );
    });
  });
});
