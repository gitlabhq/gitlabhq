function insertRow($row) {
  const $rowClone = $row.clone();
  $rowClone.removeAttr('data-is-persisted');
  $rowClone.find('input, textarea').val('');
  $row.after($rowClone);
}

function removeRow($row) {
  const isPersisted = gl.utils.convertPermissionToBoolean($row.attr('data-is-persisted'));

  if (isPersisted) {
    $row.hide();
    $row
      .find('.js-destroy-input')
      .val(1);
  } else {
    $row.remove();
  }
}

function checkIfRowTouched($row) {
  return $row.find('.js-user-input').toArray().some(el => $(el).val().length > 0);
}

function setupPipelineVariableList(parent = document) {
  const $parent = $(parent);

  $parent.on('click', '.js-row-remove-button', (e) => {
    const $row = $(e.currentTarget).closest('.js-row');
    removeRow($row);

    e.preventDefault();
  });

  // Remove any empty rows except the last r
  $parent.on('blur', '.js-user-input', (e) => {
    const $row = $(e.currentTarget).closest('.js-row');

    const isTouched = checkIfRowTouched($row);
    if ($row.is(':not(:last-child)') && !isTouched) {
      removeRow($row);
    }
  });

  // Always make sure there is an empty last row
  $parent.on('input', '.js-user-input', () => {
    const $lastRow = $parent.find('.js-row').last();

    const isTouched = checkIfRowTouched($lastRow);
    if (isTouched) {
      insertRow($lastRow);
    }
  });

  // Clear out the empty last row so it
  // doesn't get submitted and throw validation errors
  $parent.closest('form').on('submit', () => {
    const $lastRow = $parent.find('.js-row').last();

    const isTouched = checkIfRowTouched($lastRow);
    if (!isTouched) {
      $lastRow.find('input, textarea').attr('name', '');
    }
  });
}

export {
  setupPipelineVariableList,
  insertRow,
  removeRow,
};
