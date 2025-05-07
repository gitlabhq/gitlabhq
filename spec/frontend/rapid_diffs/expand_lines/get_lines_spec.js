import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getLines } from '~/rapid_diffs/expand_lines/get_lines';

describe('getLines', () => {
  const diffLinesPath = '/lines';
  const view = 'inline';
  const offset = 20;
  const maxLines = 20;

  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  it('sends correct params for up direction', async () => {
    const lineBefore = 100;
    const lineAfter = 180;
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: true,
        since: lineAfter - maxLines,
        to: lineAfter - 1,
        closest_line_number: lineBefore,
        offset,
        bottom: false,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'up',
      surroundingLines: [
        { newLineNumber: lineBefore, oldLineNumber: lineBefore - offset },
        { newLineNumber: lineAfter, oldLineNumber: lineAfter - offset },
      ],
      diffLinesPath,
      view,
    });
  });

  it('sends correct params for leading up direction', async () => {
    const lineAfter = 180;
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: true,
        since: lineAfter - maxLines,
        to: lineAfter - 1,
        closest_line_number: 0,
        offset,
        bottom: false,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'up',
      surroundingLines: [null, { newLineNumber: lineAfter, oldLineNumber: lineAfter - offset }],
      diffLinesPath,
      view,
    });
  });

  it('sends correct params for down direction', async () => {
    const lineBefore = 100;
    const lineAfter = 180;
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: true,
        closest_line_number: lineAfter,
        since: lineBefore + 1,
        to: lineBefore + maxLines,
        offset,
        bottom: true,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'down',
      surroundingLines: [
        { newLineNumber: lineBefore, oldLineNumber: lineBefore - offset },
        { newLineNumber: lineAfter, oldLineNumber: lineAfter - offset },
      ],
      diffLinesPath,
      view,
    });
  });

  it('sends correct params for trailing down direction', async () => {
    const lineBefore = 180;
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: true,
        since: lineBefore + 1,
        to: lineBefore + maxLines,
        closest_line_number: 0,
        offset,
        bottom: true,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'down',
      surroundingLines: [{ newLineNumber: lineBefore, oldLineNumber: lineBefore - offset }, null],
      diffLinesPath,
      view,
    });
  });

  it('sends correct params for both direction', async () => {
    const lineBefore = 180;
    const lineAfter = 200;
    mock.onGet('/lines').reply((config) => {
      expect(config.params).toEqual({
        unfold: false,
        since: lineBefore + 1,
        to: lineAfter - 1,
        bottom: false,
        offset,
        view: 'inline',
      });
      return [HTTP_STATUS_OK, []];
    });

    await getLines({
      expandDirection: 'both',
      surroundingLines: [
        { newLineNumber: lineBefore, oldLineNumber: lineBefore - offset },
        { newLineNumber: lineAfter, oldLineNumber: lineAfter - offset },
      ],
      diffLinesPath,
      view,
    });
  });
});
