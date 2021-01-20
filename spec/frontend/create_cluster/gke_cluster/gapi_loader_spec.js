import gapiLoader from '~/create_cluster/gke_cluster/gapi_loader';

describe('gapiLoader', () => {
  // A mock for document.head.appendChild to intercept the script tag injection.
  let mockDOMHeadAppendChild;

  beforeEach(() => {
    mockDOMHeadAppendChild = jest.spyOn(document.head, 'appendChild');
  });

  afterEach(() => {
    mockDOMHeadAppendChild.mockRestore();
    delete window.gapi;
    delete window.gapiPromise;
    delete window.onGapiLoad;
  });

  it('returns a promise', () => {
    expect(gapiLoader()).toBeInstanceOf(Promise);
  });

  it('returns the same promise when already loading', () => {
    const first = gapiLoader();
    const second = gapiLoader();
    expect(first).toBe(second);
  });

  it('resolves the promise when the script loads correctly', async () => {
    mockDOMHeadAppendChild.mockImplementationOnce((script) => {
      script.removeAttribute('src');
      script.appendChild(
        document.createTextNode(`window.gapi = 'hello gapi'; window.onGapiLoad()`),
      );
      document.head.appendChild(script);
    });
    await expect(gapiLoader()).resolves.toBe('hello gapi');
    expect(mockDOMHeadAppendChild).toHaveBeenCalled();
  });

  it('rejects the promise when the script fails loading', async () => {
    mockDOMHeadAppendChild.mockImplementationOnce((script) => {
      script.onerror(new Error('hello error'));
    });
    await expect(gapiLoader()).rejects.toThrow('hello error');
    expect(mockDOMHeadAppendChild).toHaveBeenCalled();
  });
});
