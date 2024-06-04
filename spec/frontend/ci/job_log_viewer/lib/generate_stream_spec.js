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

    expect(await fetchLogLines('/raw')).toEqual([
      { content: [{ style: [], text: '🦊🦊🦊🦊' }], sections: [] },
    ]);
  });

  it('skips an empty log line', async () => {
    mockFetchResponse(['\n']);

    expect(await fetchLogLines('/raw')).toEqual([]);
  });
});
