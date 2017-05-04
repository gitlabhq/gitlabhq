export default (newStateData, tasks) => {
  const $tasks = $('#task_status');
  const $tasksShort = $('#task_status_short');
  const $issueableHeader = $('.issuable-header');
  const tasksStates = { newState: null, currentState: null };

  if ($tasks.length === 0) {
    if (!(newStateData.task_status.indexOf('0 of 0') === 0)) {
      $issueableHeader.append(`<span id="task_status">${newStateData.task_status}</span>`);
    } else {
      $issueableHeader.append('<span id="task_status"></span>');
    }
  } else {
    tasksStates.newState = newStateData.task_status.indexOf('0 of 0') === 0;
    tasksStates.currentState = tasks.indexOf('0 of 0') === 0;
  }

  if ($tasks && !tasksStates.newState) {
    $tasks.text(newStateData.task_status);
    $tasksShort.text(newStateData.task_status);
  } else if (tasksStates.currentState) {
    $issueableHeader.append(`<span id="task_status">${newStateData.task_status}</span>`);
  } else if (tasksStates.newState) {
    $tasks.remove();
    $tasksShort.remove();
  }
};
