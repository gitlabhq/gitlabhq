import $ from 'jquery';
import Autosave from '~/autosave';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import IssuableForm from '~/issuable/issuable_form';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { getSaveableFormChildren } from './helpers';

jest.mock('~/autosave');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
confirmAction.mockResolvedValueOnce(false);

const createIssuable = (form) => {
  return new IssuableForm(form);
};

describe('IssuableForm', () => {
  let trackingSpy;
  let $form;
  let instance;

  useLocalStorageSpy();

  beforeEach(() => {
    setHTMLFixture(`
      <form>
        <input name="[title]" />
        <input type="checkbox" class="js-toggle-draft" />
        <textarea name="[description]"></textarea>
      </form>
    `);
    $form = $('form');
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  afterEach(() => {
    resetHTMLFixture();
    $form = null;
    instance = null;
  });

  describe('autosave', () => {
    let $title;

    beforeEach(() => {
      $title = $form.find('input[name*="[title]"]').get(0);
    });

    afterEach(() => {
      $title = null;
    });

    describe('initAutosave', () => {
      it('calls initAutosave', () => {
        const initAutosave = jest.spyOn(IssuableForm.prototype, 'initAutosave');
        createIssuable($form);

        expect(initAutosave).toHaveBeenCalledTimes(1);
      });

      it('creates autosave with the searchTerm included', () => {
        setWindowLocation('https://gitlab.test/foo?bar=true');
        createIssuable($form);

        expect(Autosave).toHaveBeenCalledWith(
          $title,
          ['/foo', 'bar=true', 'title'],
          'autosave//foo/bar=true=title',
        );
      });

      it("creates autosave fields without the searchTerm if it's an issue new form", () => {
        setWindowLocation('https://gitlab.test/issues/new?bar=true');
        $form.attr('data-new-issue-path', '/issues/new');
        createIssuable($form);

        expect(Autosave).toHaveBeenCalledWith(
          $title,
          ['/issues/new', '', 'title'],
          'autosave//issues/new/bar=true=title',
        );
      });

      it.each([
        {
          id: 'confidential',
          input: '<input type="checkbox" name="issue[confidential]"/>',
          selector: 'input[name*="[confidential]"]',
        },
        {
          id: 'due_date',
          input: '<input type="text" name="issue[due_date]"/>',
          selector: 'input[name*="[due_date]"]',
        },
      ])('creates $id autosave when $id input exist', ({ id, input, selector }) => {
        $form.append(input);
        const $input = $form.find(selector);
        createIssuable($form);

        const children = getSaveableFormChildren($form[0]);

        // description autosave is being handled separately
        // hence we're using children.length - 1
        expect(Autosave).toHaveBeenCalledTimes(children.length - 1);
        expect(Autosave).toHaveBeenLastCalledWith(
          $input.get(0),
          ['/', '', id],
          `autosave///=${id}`,
        );
      });
    });

    describe('resetAutosave', () => {
      it('calls reset on title', () => {
        instance = createIssuable($form);

        instance.resetAutosave();

        expect(instance.autosaves.get('title').reset).toHaveBeenCalledTimes(1);
      });

      it('resets autosave when submit', async () => {
        const resetAutosave = jest.spyOn(IssuableForm.prototype, 'resetAutosave');
        createIssuable($form);

        $form.submit();
        await waitForPromises();

        expect(resetAutosave).toHaveBeenCalledTimes(1);
      });

      it('resets autosave on elements with the .js-reset-autosave class', () => {
        const resetAutosave = jest.spyOn(IssuableForm.prototype, 'resetAutosave');
        $form.append('<a class="js-reset-autosave">Cancel</a>');
        createIssuable($form);

        $form.find('.js-reset-autosave').trigger('click');

        expect(resetAutosave).toHaveBeenCalledTimes(1);
      });

      it.each([
        { id: 'confidential', input: '<input type="checkbox" name="issue[confidential]"/>' },
        { id: 'due_date', input: '<input type="text" name="issue[due_date]"/>' },
      ])('calls reset on autosave $id when $id input exist', ({ id, input }) => {
        $form.append(input);
        instance = createIssuable($form);
        instance.resetAutosave();

        expect(instance.autosaves.get(id).reset).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('draft', () => {
    let titleField;
    let toggleDraft;

    beforeEach(() => {
      instance = createIssuable($form);
      titleField = document.querySelector('input[name="[title]"]');
      toggleDraft = document.querySelector('input.js-toggle-draft');
    });

    describe('removeDraft', () => {
      it.each`
        prefix
        ${'draFT: '}
        ${'  [DRaft] '}
        ${'drAft:'}
        ${'[draFT]'}
        ${'(draft) '}
        ${' (DrafT)'}
        ${'draft: [draft] (draft)'}
      `('removes "$prefix" from the beginning of the title', ({ prefix }) => {
        titleField.value = `${prefix}The Issuable's Title Value`;

        instance.removeDraft();

        expect(titleField.value).toBe("The Issuable's Title Value");
      });
    });

    describe('addDraft', () => {
      it("properly adds the work in progress prefix to the Issuable's title", () => {
        titleField.value = "The Issuable's Title Value";

        instance.addDraft();

        expect(titleField.value).toBe("Draft: The Issuable's Title Value");
      });
    });

    describe('isMarkedDraft', () => {
      it.each`
        title                                 | expected
        ${'draFT: something is happening'}    | ${true}
        ${'draft something is happening'}     | ${false}
        ${'something is happening to drafts'} | ${false}
        ${'something is happening'}           | ${false}
      `('returns $expected with "$title"', ({ title, expected }) => {
        titleField.value = title;

        expect(instance.isMarkedDraft()).toBe(expected);
      });
    });

    describe('readDraftStatus', () => {
      it.each`
        title                | checked
        ${'Draft: my title'} | ${true}
        ${'my title'}        | ${false}
      `(
        'sets the draft checkbox checked status to $checked when the title is $title',
        ({ title, checked }) => {
          titleField.value = title;

          instance.readDraftStatus();

          expect(toggleDraft.checked).toBe(checked);
        },
      );
    });

    describe('writeDraftStatus', () => {
      it.each`
        checked  | title
        ${true}  | ${'Draft: my title'}
        ${false} | ${'my title'}
      `(
        'updates the title to $title when the draft checkbox checked status is $checked',
        ({ checked, title }) => {
          titleField.value = 'my title';
          toggleDraft.checked = checked;

          instance.writeDraftStatus();

          expect(titleField.value).toBe(title);
        },
      );
    });
  });

  describe('Checks for sensitive token', () => {
    let issueDescription;
    const sensitiveMessage = 'token: glpat-1234567890abcdefghij';

    beforeEach(() => {
      issueDescription = $form.find('textarea[name*="[description]"]').get(0);
    });

    afterEach(() => {
      issueDescription = null;
    });

    it('submits the form when no token is present', async () => {
      issueDescription.value = 'sample message';

      const handleSubmit = jest.spyOn(IssuableForm.prototype, 'handleSubmit');
      const resetAutosave = jest.spyOn(IssuableForm.prototype, 'resetAutosave');
      createIssuable($form);

      $form.submit();
      await waitForPromises();

      expect(handleSubmit).toHaveBeenCalled();
      expect(resetAutosave).toHaveBeenCalled();
    });

    it.each`
      windowLocation                                        | property          | localStorageValue  | value
      ${'/gitlab-org/gitlab/-/issues/412699'}               | ${'Issue'}        | ${'contentEditor'} | ${1}
      ${'/gitlab-org/gitlab/-/merge_requests/125979/diffs'} | ${'MergeRequest'} | ${'contentEditor'} | ${1}
      ${'/groups/gitlab-org/-/milestones/8/edit'}           | ${'Other'}        | ${'contentEditor'} | ${1}
      ${'/gitlab-org/gitlab/-/issues/412699'}               | ${'Issue'}        | ${'markdownField'} | ${0}
      ${'/gitlab-org/gitlab/-/merge_requests/125979/diffs'} | ${'MergeRequest'} | ${'markdownField'} | ${0}
      ${'/groups/gitlab-org/-/milestones/8/edit'}           | ${'Other'}        | ${'markdownField'} | ${0}
    `('tracks event on form submit', ({ windowLocation, property, localStorageValue, value }) => {
      setWindowLocation(`${TEST_HOST}/${windowLocation}`);
      localStorage.setItem('gl-markdown-editor-mode', localStorageValue);

      issueDescription.value = 'sample message';

      createIssuable($form);

      $form.submit();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
        label: value ? 'rich_text_editor' : 'markdown_editor',
        property,
      });
    });

    it('prevents form submission when token is present', async () => {
      issueDescription.value = sensitiveMessage;

      const handleSubmit = jest.spyOn(IssuableForm.prototype, 'handleSubmit');
      const resetAutosave = jest.spyOn(IssuableForm.prototype, 'resetAutosave');
      createIssuable($form);

      $form.submit();
      await waitForPromises();

      expect(handleSubmit).toHaveBeenCalled();
      expect(resetAutosave).not.toHaveBeenCalled();
      expect(confirmAction).toHaveBeenCalledWith(
        '',
        expect.objectContaining({ title: 'Warning: Potential secret detected' }),
      );
    });
  });
});
