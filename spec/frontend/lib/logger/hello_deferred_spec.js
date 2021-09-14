import waitForPromises from 'helpers/wait_for_promises';
import { logHello } from '~/lib/logger/hello';
import { logHelloDeferred } from '~/lib/logger/hello_deferred';

jest.mock('~/lib/logger/hello');

describe('~/lib/logger/hello_deferred', () => {
  it('dynamically imports and calls logHello', async () => {
    logHelloDeferred();

    expect(logHello).not.toHaveBeenCalled();

    await waitForPromises();

    expect(logHello).toHaveBeenCalled();
  });
});
