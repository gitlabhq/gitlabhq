/* eslint-disable no-console */
import { getCLS, getFID, getLCP } from 'web-vitals';

const initVitalsLog = () => {
  const reportVital = data => {
    console.log(`${String.fromCodePoint(0x1f4c8)} ${data.name} : `, data);
  };

  console.log(
    `${String.fromCodePoint(
      0x1f4d1,
    )} To get the final web vital numbers reported you maybe need to switch away and back to the tab`,
  );
  getCLS(reportVital);
  getFID(reportVital);
  getLCP(reportVital);
};

const initPerformanceBarLog = () => {
  console.log(
    `%c ${String.fromCodePoint(0x1f98a)} GitLab performance bar`,
    'width:100%;background-color: #292961; color: #FFFFFF; font-size:24px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto; padding: 10px;display:block;padding-right: 100px;',
  );

  initVitalsLog();
};

export default initPerformanceBarLog;
