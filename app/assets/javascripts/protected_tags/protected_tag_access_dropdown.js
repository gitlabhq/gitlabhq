import { ProtectedRefAccessDropdown } from '../protected_refs';

export default class ProtectedTagAccessDropdown extends ProtectedRefAccessDropdown {
  constructor(options) {
    super(options, {
      inputId: 'input-id',
      fieldName: 'field-name',
      activeCls: '.is-active',
    });
  }
}
