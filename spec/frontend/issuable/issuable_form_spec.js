import $ from 'jquery';

import IssuableForm from '~/issuable/issuable_form';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('IssuableForm', () => {
  let instance;

  const createIssuable = (form) => {
    instance = new IssuableForm(form);
  };

  beforeEach(() => {
    setFixtures(`
      <form>
        <input name="[title]" />
      </form>
    `);
    createIssuable($('form'));
  });

  describe('initAutosave', () => {
    it('creates autosave with the searchTerm included', () => {
      setWindowLocation('https://gitlab.test/foo?bar=true');
      const autosave = instance.initAutosave();

      expect(autosave.key.includes('bar=true')).toBe(true);
    });

    it("creates autosave fields without the searchTerm if it's an issue new form", () => {
      setFixtures(`
        <form data-new-issue-path="/issues/new">
          <input name="[title]" />
        </form>
      `);
      createIssuable($('form'));

      setWindowLocation('https://gitlab.test/issues/new?bar=true');

      const autosave = instance.initAutosave();

      expect(autosave.key.includes('bar=true')).toBe(false);
    });
  });

  describe('removeWip', () => {
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
      instance.titleField.val(`${prefix}The Issuable's Title Value`);

      instance.removeWip();

      expect(instance.titleField.val()).toBe("The Issuable's Title Value");
    });
  });

  describe('addWip', () => {
    it("properly adds the work in progress prefix to the Issuable's title", () => {
      instance.titleField.val("The Issuable's Title Value");

      instance.addWip();

      expect(instance.titleField.val()).toBe("Draft: The Issuable's Title Value");
    });
  });

  describe('workInProgress', () => {
    it.each`
      title                                 | expected
      ${'draFT: something is happening'}    | ${true}
      ${'draft something is happening'}     | ${false}
      ${'something is happening to drafts'} | ${false}
      ${'something is happening'}           | ${false}
    `('returns $expected with "$title"', ({ title, expected }) => {
      instance.titleField.val(title);

      expect(instance.workInProgress()).toBe(expected);
    });
  });
});
