export default (apiData, tasks) => {
  const $tasks = $('#task_status');
  const $tasksShort = $('#task_status_short');
  const $issueableHeader = $('.issuable-header');
  const zeroData = { api: null, tasks: null };

  if ($tasks.length === 0) {
    if (!(apiData.task_status.indexOf('0 of 0') >= 0)) {
      $issueableHeader.append(`<span id="task_status">${apiData.task_status}</span>`);
    } else {
      $issueableHeader.append('<span id="task_status"></span>');
    }
  } else {
    zeroData.api = apiData.task_status.indexOf('0 of 0') >= 0;
    zeroData.tasks = tasks.indexOf('0 of 0') >= 0;
  }

  if ($tasks && !zeroData.api) {
    $tasks.text(apiData.task_status);
    $tasksShort.text(apiData.task_status);
  } else if (zeroData.tasks) {
    $issueableHeader.append(`<span id="task_status">${apiData.task_status}</span>`);
  } else if (zeroData.api) {
    $tasks.remove();
    $tasksShort.remove();
  }
};
