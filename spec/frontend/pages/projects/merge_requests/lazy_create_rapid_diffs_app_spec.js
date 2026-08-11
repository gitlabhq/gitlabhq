describe('lazyCreateRapidDiffsApp', () => {
  const originalGon = window.gon;

  const loadModule = () => {
    jest.resetModules();
    return import('~/pages/projects/merge_requests/lazy_create_rapid_diffs_app');
  };

  afterEach(() => {
    window.gon = originalGon;
  });

  it('provides a factory when the server resolved the page to Rapid Diffs', async () => {
    window.gon = { rapid_diffs_page_enabled: true };

    const { lazyCreateRapidDiffsApp } = await loadModule();

    expect(lazyCreateRapidDiffsApp).toEqual(expect.any(Function));
  });

  it('provides no factory when the server resolved the page to legacy diffs', async () => {
    window.gon = { rapid_diffs_page_enabled: false };

    const { lazyCreateRapidDiffsApp } = await loadModule();

    expect(lazyCreateRapidDiffsApp).toBeNull();
  });

  it('provides no factory when the server did not resolve the page', async () => {
    window.gon = {};

    const { lazyCreateRapidDiffsApp } = await loadModule();

    expect(lazyCreateRapidDiffsApp).toBeNull();
  });
});
