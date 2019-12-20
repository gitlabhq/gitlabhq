import $ from 'jquery';

import { loadHTMLFixture } from 'helpers/fixtures';
import setupTransferEdit from '~/transfer_edit';

describe('setupTransferEdit', () => {
  const formSelector = '.js-project-transfer-form';
  const targetSelector = 'select.select2';

  beforeEach(() => {
    loadHTMLFixture('projects/edit.html');
    setupTransferEdit(formSelector, targetSelector);
  });

  it('disables submit button on load', () => {
    expect(
      $(formSelector)
        .find(':submit')
        .prop('disabled'),
    ).toBe(true);
  });

  it('enables submit button when selection changes to non-empty value', () => {
    const nonEmptyValue = $(formSelector)
      .find(targetSelector)
      .find('option')
      .not(':empty')
      .val();
    $(formSelector)
      .find(targetSelector)
      .val(nonEmptyValue)
      .trigger('change');

    expect(
      $(formSelector)
        .find(':submit')
        .prop('disabled'),
    ).toBeFalsy();
  });

  it('disables submit button when selection changes to empty value', () => {
    $(formSelector)
      .find(targetSelector)
      .val('')
      .trigger('change');

    expect(
      $(formSelector)
        .find(':submit')
        .prop('disabled'),
    ).toBe(true);
  });
});
