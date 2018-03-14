import $ from 'jquery';
import VariableList from './ci_variable_list';

// Used for the variable list on scheduled pipeline edit page
export default function setupNativeFormVariableList({
  container,
  formField = 'variables',
}) {
  const $container = $(container);

  const variableList = new VariableList({
    container: $container,
    formField,
  });
  variableList.init();

  // Clear out the names in the empty last row so it
  // doesn't get submitted and throw validation errors
  $container.closest('form').on('submit trigger-submit', () => {
    const $lastRow = $container.find('.js-row').last();

    const isTouched = variableList.checkIfRowTouched($lastRow);
    if (!isTouched) {
      $lastRow.find('input, textarea').attr('name', '');
    }
  });
}
