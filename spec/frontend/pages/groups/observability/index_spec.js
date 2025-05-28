import initObservability from '~/observability/index';

jest.mock('~/observability/index');

describe('Groups Observability Page', () => {
  let originalDocument;

  beforeEach(() => {
    jest.clearAllMocks();
    originalDocument = document.body.innerHTML;
  });

  afterEach(() => {
    document.body.innerHTML = originalDocument;
  });

  it('calls initObservability exactly once without arguments', async () => {
    document.body.innerHTML = '<div id="js-observability"></div>';
    await import('~/pages/groups/observability');

    expect(initObservability).toHaveBeenCalledTimes(1);
    expect(initObservability).toHaveBeenCalledWith();
  });

  it('does not initialize when required DOM element is missing', async () => {
    document.body.innerHTML = '';
    await import('~/pages/groups/observability');

    expect(initObservability).not.toHaveBeenCalled();
  });
});
