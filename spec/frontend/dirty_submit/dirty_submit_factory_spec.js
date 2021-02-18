import DirtySubmitCollection from '~/dirty_submit/dirty_submit_collection';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import DirtySubmitForm from '~/dirty_submit/dirty_submit_form';
import { createForm } from './helper';

describe('DirtySubmitCollection', () => {
  it('returns a DirtySubmitForm instance for single form elements', () => {
    const { form } = createForm();

    expect(dirtySubmitFactory(form) instanceof DirtySubmitForm).toBe(true);
  });

  it('returns a DirtySubmitCollection instance for a collection of form elements', () => {
    const forms = [createForm().form, createForm().form];

    expect(dirtySubmitFactory(forms) instanceof DirtySubmitCollection).toBe(true);
  });
});
