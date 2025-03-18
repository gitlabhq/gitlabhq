import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getLines } from '~/rapid_diffs/expand_lines/get_lines';

describe('getLines', () => {
  const diffLinesPath = '/lines';
  const view = 'inline';
  const surroundingLines = [
    { newLineNumber: 10, oldLineNumber: 8 },
    { newLineNumber: 20, oldLineNumber: 18 },
  ];

  it('sends correct params for up direction', async () => {
    const mock = new MockAdapter(axios);
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: true,
        since: 1,
        to: 19,
        closest_line_number: 10,
        offset: 2,
        bottom: false,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'up',
      surroundingLines,
      diffLinesPath,
      view,
    });
  });

  it('sends correct params for down direction', async () => {
    const mock = new MockAdapter(axios);
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: true,
        since: 11,
        to: 31,
        closest_line_number: 20,
        offset: 2,
        bottom: true,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'down',
      surroundingLines,
      diffLinesPath,
      view,
    });
  });

  it('sends correct params for both direction', async () => {
    const mock = new MockAdapter(axios);
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: false,
        since: 11,
        to: 19,
        bottom: false,
        offset: 2,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'both',
      surroundingLines,
      diffLinesPath,
      view,
    });
  });
});
