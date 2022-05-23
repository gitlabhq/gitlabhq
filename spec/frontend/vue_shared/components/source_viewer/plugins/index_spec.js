import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import { HLJS_ON_AFTER_HIGHLIGHT } from '~/vue_shared/components/source_viewer/constants';
import wrapComments from '~/vue_shared/components/source_viewer/plugins/wrap_comments';

jest.mock('~/vue_shared/components/source_viewer/plugins/wrap_comments');
const hljsMock = { addPlugin: jest.fn() };

describe('Highlight.js plugin registration', () => {
  beforeEach(() => registerPlugins(hljsMock));

  it('registers our plugins', () => {
    expect(hljsMock.addPlugin).toHaveBeenCalledWith({ [HLJS_ON_AFTER_HIGHLIGHT]: wrapComments });
  });
});
