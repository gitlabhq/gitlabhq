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
      ${'drAft '}
      ${'draFT: '}
      ${'  [DRaft] '}
      ${'drAft:'}
      ${'[draFT]'}
      ${' dRaFt - '}
      ${'dRaFt -      '}
      ${'(draft) '}
      ${' (DrafT)'}
      ${'draft draft - draft: [draft] (draft)'}
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
});
