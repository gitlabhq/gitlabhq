import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { confirmJobConfirmationMessage } from '~/ci/pipeline_details/graph/utils';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

describe('confirmJobConfirmationMessage', () => {
  beforeEach(() => {
    confirmAction.mockReset();
  });

  const findModalHtmlMessage = () => confirmAction.mock.calls[0][1].modalHtmlMessage;

  it('escapes HTML in the confirmation message instead of rendering it', () => {
    confirmJobConfirmationMessage('test_job', '<img src=x onerror=alert(1)>');

    expect(findModalHtmlMessage()).toContain('&lt;img src=x onerror=alert(1)&gt;');
    expect(findModalHtmlMessage()).not.toContain('<img src=x onerror=alert(1)>');
  });
});
