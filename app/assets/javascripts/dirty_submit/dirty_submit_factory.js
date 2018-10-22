import DirtySubmitCollection from './dirty_submit_collection';
import DirtySubmitForm from './dirty_submit_form';

export default function dirtySubmitFactory(formOrForms) {
  const isCollection = formOrForms instanceof NodeList || formOrForms instanceof Array;
  const DirtySubmitClass = isCollection ? DirtySubmitCollection : DirtySubmitForm;

  return new DirtySubmitClass(formOrForms);
}
