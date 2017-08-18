import CloseReopenReportToggle from '../close_reopen_report_toggle';

function initCloseReopenReport() {
  const container = document.querySelector('.js-issuable-close-dropdown');

  if (!container) return undefined;

  const dropdownTrigger = container.querySelector('.js-issuable-close-toggle');
  const dropdownList = container.querySelector('.js-issuable-close-menu');
  const button = container.querySelector('.js-issuable-close-button');

  const closeReopenReportToggle = new CloseReopenReportToggle({
    dropdownTrigger,
    dropdownList,
    button,
  });

  closeReopenReportToggle.initDroplab();

  return closeReopenReportToggle;
}

const IssuablesHelper = {
  initCloseReopenReport,
};

export default IssuablesHelper;
