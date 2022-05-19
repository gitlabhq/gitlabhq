import { setHTMLFixture, resetHTMLFixture } from 'jest/__helpers__/fixtures';
import initCheckFormState from '~/pages/projects/merge_requests/edit/check_form_state';

describe('Check form state', () => {
  const findInput = () => document.querySelector('#form-input');

  let beforeUnloadEvent;
  let setDialogContent;

  beforeEach(() => {
    setHTMLFixture(`
      <form class="merge-request-form">
        <input type="text" name="test" id="form-input"/>
      </form>`);

    beforeUnloadEvent = new Event('beforeunload');
    jest.spyOn(beforeUnloadEvent, 'preventDefault');
    setDialogContent = jest.spyOn(beforeUnloadEvent, 'returnValue', 'set');

    initCheckFormState();
  });

  afterEach(() => {
    beforeUnloadEvent.preventDefault.mockRestore();
    setDialogContent.mockRestore();

    resetHTMLFixture();
  });

  it('shows confirmation dialog when there are unsaved changes', () => {
    findInput().value = 'value changed';
    window.dispatchEvent(beforeUnloadEvent);

    expect(beforeUnloadEvent.preventDefault).toHaveBeenCalled();
    expect(setDialogContent).toHaveBeenCalledWith('');
  });

  it('does not show confirmation dialog when there are no unsaved changes', () => {
    window.dispatchEvent(beforeUnloadEvent);

    expect(beforeUnloadEvent.preventDefault).not.toHaveBeenCalled();
    expect(setDialogContent).not.toHaveBeenCalled();
  });
});
