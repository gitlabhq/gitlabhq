import { fetchLogLines } from '~/ci/job_log_viewer/lib/generate_stream';

const mockFetchResponse = (chunks) => {
  const encoder = new TextEncoder();
  const queue = chunks.map((chunk) => encoder.encode(chunk));

  global.fetch.mockResolvedValue({
    body: {
      getReader() {
        return new ReadableStream({
          pull(controller) {
            if (queue.length) {
              controller.enqueue(queue.shift());
            } else {
              controller.close();
            }
          },
        }).getReader();
      },
    },
  });
};

describe('generate stream', () => {
  beforeEach(() => {
    global.fetch = jest.fn();
  });

  it('uses path to fetch', async () => {
    mockFetchResponse([]);

    await fetchLogLines('/jobs/1/raw');

    expect(global.fetch).toHaveBeenCalledWith('/jobs/1/raw');
  });

  it('fetches line', async () => {
    mockFetchResponse(['line 1']);

    expect(await fetchLogLines()).toEqual([
      { content: [{ style: [], text: 'line 1' }], sections: [] },
    ]);
  });

  it('fetches timestamped line', async () => {
    mockFetchResponse(['2024-01-01T01:02:03.123456Z 00O line 1']);

    expect(await fetchLogLines()).toEqual([
      {
        content: [{ style: [], text: 'line 1' }],
        sections: [],
        timestamp: '2024-01-01T01:02:03.123456Z',
      },
    ]);
  });

  it('fetches lines', async () => {
    mockFetchResponse(['line 1\nline 2']);

    expect(await fetchLogLines()).toEqual([
      { content: [{ style: [], text: 'line 1' }], sections: [] },
      { content: [{ style: [], text: 'line 2' }], sections: [] },
    ]);
  });

  it('fetches lines in separate chunks', async () => {
    mockFetchResponse(['line 1\nline 2\n', 'line 3\nline 4']);

    expect(await fetchLogLines()).toEqual([
      { content: [{ style: [], text: 'line 1' }], sections: [] },
      { content: [{ style: [], text: 'line 2' }], sections: [] },
      { content: [{ style: [], text: 'line 3' }], sections: [] },
      { content: [{ style: [], text: 'line 4' }], sections: [] },
    ]);
  });

  it.each`
    case                          | chunks
    ${'chunks'}                   | ${['line 1\nli', 'ne 2\nline 3']}
    ${'empty chunks'}             | ${['line 1\nli', '', 'ne 2\nline 3']}
    ${'empty chunks with spaces'} | ${['line 1\nli', 'ne', '', ' ', '', '2\nline 3']}
  `('fetches lines split across $case', async ({ chunks }) => {
    mockFetchResponse(chunks);

    expect(await fetchLogLines()).toEqual([
      { content: [{ style: [], text: 'line 1' }], sections: [] },
      { content: [{ style: [], text: 'line 2' }], sections: [] },
      { content: [{ style: [], text: 'line 3' }], sections: [] },
    ]);
  });

  it('decodes using utf-8', async () => {
    mockFetchResponse(['🦊🦊🦊🦊']);

    expect(await fetchLogLines()).toEqual([
      { content: [{ style: [], text: '🦊🦊🦊🦊' }], sections: [] },
    ]);
  });

  it('decodes lines from a windows runner', async () => {
    mockFetchResponse([
      'Running with ru',
      'nner 16.5.0\n',
      'Very long line\r\n',
      'Progress 1...\rProgress 2...\rDone\r\n',
      'Separated\r',
      '\n',
    ]);

    expect(await fetchLogLines()).toEqual([
      { content: [{ style: [], text: 'Running with runner 16.5.0' }], sections: [] },
      { content: [{ style: [], text: 'Very long line' }], sections: [] },
      { content: [{ style: [], text: 'Done' }], sections: [] },
      { content: [{ style: [], text: 'Separated' }], sections: [] },
    ]);
  });

  it('appends to an existing timestamped line', async () => {
    mockFetchResponse([
      '2024-01-01T01:01:01.123456Z 00O line...\n2024-01-01T02:02:02.123456Z 00O+...content',
    ]);

    expect(await fetchLogLines()).toEqual([
      {
        content: [
          { style: [], text: 'line...' },
          { style: [], text: '...content' },
        ],
        sections: [],
        timestamp: '2024-01-01T02:02:02.123456Z',
      },
    ]);
  });

  it('skips an empty log line', async () => {
    mockFetchResponse(['\n']);

    expect(await fetchLogLines()).toEqual([]);
  });

  it('skips an empty timestamped log line', async () => {
    mockFetchResponse([
      '2024-01-01T01:01:01.123456Z 00O line...\n2024-01-01T02:02:02.123456Z 00O+',
    ]);

    expect(await fetchLogLines()).toEqual([
      {
        content: [{ style: [], text: 'line...' }],
        sections: [],
        timestamp: '2024-01-01T01:01:01.123456Z',
      },
    ]);
  });

  describe('with a line that contains carriage returns', () => {
    it('decodes the last content', async () => {
      mockFetchResponse(['enumerating objects 50%\renumerating objects 100%\n']);

      expect(await fetchLogLines()).toEqual([
        { content: [{ style: [], text: 'enumerating objects 100%' }], sections: [] },
      ]);
    });

    it('decodes the last content across chunks', async () => {
      mockFetchResponse(['enumerating 50%\r', 'enumerating ', '80%\r', 'waiting\rdone\n']);

      expect(await fetchLogLines()).toEqual([
        { content: [{ style: [], text: 'done' }], sections: [] },
      ]);
    });

    it('preserves section headings', async () => {
      mockFetchResponse(['section_start:1718017824:get_sources\rGetting sources']);

      expect(await fetchLogLines()).toEqual([
        {
          content: [
            {
              style: [],
              text: 'Getting sources',
            },
          ],
          sections: [],
          header: 'get_sources',
        },
      ]);
    });
  });
});
