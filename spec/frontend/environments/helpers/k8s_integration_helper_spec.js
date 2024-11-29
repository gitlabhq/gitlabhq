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
      suspended | status            | type             | reason                | statusText                    | statusMessage
      ${false}  | ${STATUS_TRUE}    | ${'Stalled'}     | ${''}                 | ${'stalled'}                  | ${{ message }}
      ${false}  | ${STATUS_TRUE}    | ${'Reconciling'} | ${''}                 | ${'reconciling'}              | ${''}
      ${false}  | ${STATUS_UNKNOWN} | ${'Ready'}       | ${REASON_PROGRESSING} | ${'reconcilingWithBadConfig'} | ${{ message }}
      ${false}  | ${STATUS_TRUE}    | ${'Ready'}       | ${''}                 | ${'reconciled'}               | ${''}
      ${false}  | ${STATUS_FALSE}   | ${'Ready'}       | ${''}                 | ${'failed'}                   | ${''}
      ${true}   | ${STATUS_FALSE}   | ${'Ready'}       | ${''}                 | ${'suspended'}                | ${''}
      ${false}  | ${STATUS_UNKNOWN} | ${'Ready'}       | ${''}                 | ${'unknown'}                  | ${''}
    `(
      'renders sync status as $statusText when status is $status, type is $type, and reason is $reason',
      ({ suspended, status, type, reason, statusText, statusMessage }) => {
        fluxConditions = [
          {
            status,
            type,
            reason,
            message,
          },
        ];

        const fluxResourceStatus = { conditions: fluxConditions, suspend: suspended };

        expect(fluxSyncStatus(fluxResourceStatus)).toMatchObject({
          status: statusText,
          ...statusMessage,
        });
      },
    );
  });

  describe('updateFluxRequested', () => {
    const defaultPath = '/metadata/annotations/reconcile.fluxcd.io~1requestedAt';
    const defaultValue = new Date().toISOString();
    const customPath = '/custom/path';
    const customValue = true;

    it.each([
      ['with default values', undefined, undefined],
      ['with custom path', customPath, undefined],
      ['with custom value', undefined, customValue],
      ['with custom path and value', customPath, customValue],
    ])('%s', (description, path, value) => {
      expect(updateFluxRequested({ path, value })).toEqual(
        JSON.stringify([
          {
            op: 'replace',
            path: path || defaultPath,
            value: value || defaultValue,
          },
        ]),
      );
    });
  });
});
