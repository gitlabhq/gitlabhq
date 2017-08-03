export default class GeoNodeForm {
  constructor(container) {
    this.$container = container;
    this.$namespaces = this.$container.find('.js-namespaces');
    this.$namespacesSelect = this.$namespaces.find('.select2');
    this.$primaryCheckbox = this.$container.find("input[type='checkbox']");
    this.$primaryCheckbox.on('change', () => this.onPrimaryCheckboxChange());
  }

  onPrimaryCheckboxChange() {
    this.$namespacesSelect.select2('data', null);
    this.$namespaces.toggleClass('hidden', this.$primaryCheckbox.is(':checked'));
  }
}
