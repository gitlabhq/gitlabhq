import MockAdapter from 'axios-mock-adapter';
import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import { STATUSES } from '~/import_entities/constants';
import { StatusPoller } from '~/import_entities/import_groups/graphql/services/status_poller';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';

jest.mock('visibilityjs');
jest.mock('~/flash');
jest.mock('~/lib/utils/poll');
jest.mock('~/import_entities/import_groups/graphql/services/source_groups_manager', () => ({
  SourceGroupsManager: jest.fn().mockImplementation(function mock() {
    this.setImportStatus = jest.fn();
    this.findByImportId = jest.fn();
  }),
}));

const FAKE_POLL_PATH = '/fake/poll/path';

describe('Bulk import status poller', () => {
  let poller;
  let mockAdapter;
  let updateImportStatus;

  const getPollHistory = () => mockAdapter.history.get.filter((x) => x.url === FAKE_POLL_PATH);

  beforeEach(() => {
    mockAdapter = new MockAdapter(axios);
    mockAdapter.onGet(FAKE_POLL_PATH).reply(200, {});
    updateImportStatus = jest.fn();
    poller = new StatusPoller({ updateImportStatus, pollPath: FAKE_POLL_PATH });
  });

  it('creates poller with proper config', () => {
    expect(Poll.mock.calls).toHaveLength(1);
    const [[pollConfig]] = Poll.mock.calls;
    expect(typeof pollConfig.method).toBe('string');

    const pollOperation = pollConfig.resource[pollConfig.method];
    expect(typeof pollOperation).toBe('function');
  });

  it('invokes axios when polling is performed', async () => {
    const [[pollConfig]] = Poll.mock.calls;
    const pollOperation = pollConfig.resource[pollConfig.method];
    expect(getPollHistory()).toHaveLength(0);

    pollOperation();
    await axios.waitForAll();

    expect(getPollHistory()).toHaveLength(1);
  });

  it('subscribes to visibility changes', () => {
    expect(Visibility.change).toHaveBeenCalled();
  });

  it.each`
    isHidden | action
    ${true}  | ${'stop'}
    ${false} | ${'restart'}
  `('$action polling when hidden is $isHidden', ({ action, isHidden }) => {
    const [pollInstance] = Poll.mock.instances;
    const [[changeHandler]] = Visibility.change.mock.calls;
    Visibility.hidden.mockReturnValue(isHidden);
    expect(pollInstance[action]).not.toHaveBeenCalled();

    changeHandler();

    expect(pollInstance[action]).toHaveBeenCalled();
  });

  it('does not perform polling when constructed', async () => {
    await axios.waitForAll();

    expect(getPollHistory()).toHaveLength(0);
  });

  it('immediately start polling when requested', async () => {
    const [pollInstance] = Poll.mock.instances;

    poller.startPolling();

    expect(pollInstance.makeRequest).toHaveBeenCalled();
  });

  it('when error occurs shows flash with error', () => {
    const [[pollConfig]] = Poll.mock.calls;
    pollConfig.errorCallback();
    expect(createFlash).toHaveBeenCalled();
  });

  it('when success response arrives updates relevant group status', () => {
    const FAKE_ID = 5;
    const [[pollConfig]] = Poll.mock.calls;
    const FAKE_RESPONSE = { id: FAKE_ID, status_name: STATUSES.FINISHED };
    pollConfig.successCallback({ data: [FAKE_RESPONSE] });

    expect(updateImportStatus).toHaveBeenCalledWith(FAKE_RESPONSE);
  });
});
