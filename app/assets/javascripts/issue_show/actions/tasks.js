export default (apiData, tasks) => {
  const $tasks = $('#task_status');
  const $tasksShort = $('#task_status_short');
  const $issueableHeader = $('.issuable-header');
  const tasksStates = { api: null, tasks: null };

  if ($tasks.length === 0) {
    if (!(apiData.task_status.indexOf('0 of 0') === 0)) {
      $issueableHeader.append(`<span id="task_status">${apiData.task_status}</span>`);
    } else {
      $issueableHeader.append('<span id="task_status"></span>');
    }
  } else {
    tasksStates.api = apiData.task_status.indexOf('0 of 0') === 0;
    tasksStates.tasks = tasks.indexOf('0 of 0') === 0;
  }

  if ($tasks && !tasksStates.api) {
    $tasks.text(apiData.task_status);
    $tasksShort.text(apiData.task_status);
  } else if (tasksStates.tasks) {
    $issueableHeader.append(`<span id="task_status">${apiData.task_status}</span>`);
  } else if (tasksStates.api) {
    $tasks.remove();
    $tasksShort.remove();
  }
};
