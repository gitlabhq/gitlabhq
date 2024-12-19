import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import blobBundle from '~/blob_edit/blob_bundle';
import initBlobEditHeader from '~/blob_edit/blob_edit_header';

import SourceEditor from '~/blob_edit/edit_blob';
import { createAlert } from '~/alert';

jest.mock('~/blob_edit/edit_blob');
jest.mock('~/alert');
jest.mock('~/blob_edit/blob_edit_header');

describe('BlobBundle', () => {
  beforeAll(() => {
    // HACK: Workaround readonly property in Jest
    Object.defineProperty(window, 'onbeforeunload', {
      writable: true,
    });
  });

  it('does not load SourceEditor by default', () => {
    blobBundle();
    expect(SourceEditor).not.toHaveBeenCalled();
  });

  it('loads SourceEditor for the edit screen', async () => {
    setHTMLFixture(`<div class="js-edit-blob-form"></div>`);
    blobBundle();
    await waitForPromises();
    expect(SourceEditor).toHaveBeenCalled();
    expect(initBlobEditHeader).toHaveBeenCalledTimes(1);
    expect(initBlobEditHeader).toHaveBeenCalledWith(expect.any(SourceEditor));
    resetHTMLFixture();
  });

  describe('No Suggest Popover', () => {
    beforeEach(() => {
      setHTMLFixture(`
      <div class="js-edit-blob-form" data-blob-filename="blah">
        <button class="js-commit-button"></button>
        <button id='cancel-changes'></button>
      </div>`);

      blobBundle();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('sets the window beforeunload listener to a function returning a string', () => {
      expect(window.onbeforeunload()).toBe('');
    });

    it('removes beforeunload listener if commit button is clicked', () => {
      $('.js-commit-button').click();

      expect(window.onbeforeunload).toBeNull();
    });

    it('removes beforeunload listener when cancel link is clicked', () => {
      $('#cancel-changes').click();

      expect(window.onbeforeunload).toBeNull();
    });
  });

  describe('Error handling', () => {
    let message;
    beforeEach(() => {
      setHTMLFixture(`<div class="js-edit-blob-form" data-blob-filename="blah"></div>`);
      message = 'Foo';
      SourceEditor.mockImplementation(() => {
        throw new Error(message);
      });
    });

    afterEach(() => {
      resetHTMLFixture();
      SourceEditor.mockClear();
    });

    it('correctly outputs error message when it occurs', async () => {
      blobBundle();
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });

  describe('commit button', () => {
    const findCommitButton = () => document.querySelector('.js-commit-button');
    const findCommitLoadingButton = () => document.querySelector('.js-commit-button-loading');

    it('hides the commit button and displays the loading button when clicked', () => {
      setHTMLFixture(
        `<div class="js-edit-blob-form">
          <button class="js-commit-button"></button>
          <button class="js-commit-button-loading gl-hidden"></button>
        </div>`,
      );
      blobBundle();
      findCommitButton().click();

      expect(findCommitButton().classList).toContain('gl-hidden');
      expect(findCommitLoadingButton().classList).not.toContain('gl-hidden');
    });
  });
});
