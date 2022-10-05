import {
  registerPlugins,
  HLJS_ON_AFTER_HIGHLIGHT,
} from '~/vue_shared/components/source_viewer/plugins/index';
import wrapComments from '~/vue_shared/components/source_viewer/plugins/wrap_comments';
import wrapBidiChars from '~/vue_shared/components/source_viewer/plugins/wrap_bidi_chars';

jest.mock('~/vue_shared/components/source_viewer/plugins/wrap_comments');
const hljsMock = { addPlugin: jest.fn() };

describe('Highlight.js plugin registration', () => {
  beforeEach(() => registerPlugins(hljsMock));

  it('registers our plugins', () => {
    expect(hljsMock.addPlugin).toHaveBeenCalledWith({ [HLJS_ON_AFTER_HIGHLIGHT]: wrapBidiChars });
    expect(hljsMock.addPlugin).toHaveBeenCalledWith({ [HLJS_ON_AFTER_HIGHLIGHT]: wrapComments });
  });
});
