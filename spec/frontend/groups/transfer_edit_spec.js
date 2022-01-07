import $ from 'jquery';

import { loadHTMLFixture } from 'helpers/fixtures';
import setupTransferEdit from '~/groups/transfer_edit';

describe('setupTransferEdit', () => {
  const formSelector = '.js-group-transfer-form';
  const targetSelector = '#new_parent_group_id';

  beforeEach(() => {
    loadHTMLFixture('groups/edit.html');
    setupTransferEdit(formSelector, targetSelector);
  });

  it('disables submit button on load', () => {
    expect($(formSelector).find(':submit').prop('disabled')).toBe(true);
  });

  it('enables submit button when selection changes to non-empty value', () => {
    const lastValue = $(formSelector).find(targetSelector).find('.dropdown-content li').last();
    $(formSelector).find(targetSelector).val(lastValue).trigger('change');

    expect($(formSelector).find(':submit').prop('disabled')).toBeFalsy();
  });

  it('disables submit button when selection changes to empty value', () => {
    $(formSelector).find(targetSelector).val('').trigger('change');

    expect($(formSelector).find(':submit').prop('disabled')).toBe(true);
  });
});
