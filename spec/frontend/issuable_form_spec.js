import $ from 'jquery';

import IssuableForm from '~/issuable_form';

function createIssuable() {
  const instance = new IssuableForm($(document.createElement('form')));

  instance.titleField = $(document.createElement('input'));

  return instance;
}

describe('IssuableForm', () => {
  let instance;

  beforeEach(() => {
    instance = createIssuable();
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
