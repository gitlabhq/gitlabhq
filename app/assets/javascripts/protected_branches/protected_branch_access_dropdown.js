import { ProtectedRefAccessDropdown } from '../protected_refs';

export default class ProtectedBranchAccessDropdown extends ProtectedRefAccessDropdown {
  constructor(options) {
    super(options, {
      inputId: 'input-id',
      fieldName: 'field-name',
      activeCls: '.is-active',
    });
  }
}
