import Code from '~/content_editor/extensions/code';
import { EXTENSION_PRIORITY_LOWER } from '~/content_editor/constants';

describe('content_editor/extensions/code', () => {
  it('has a lower loading priority', () => {
    expect(Code.config.priority).toBe(EXTENSION_PRIORITY_LOWER);
  });
});
