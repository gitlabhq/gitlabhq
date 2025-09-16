import initSetHelperText, {
  initOptionMetricsState,
  initUsagePingGenerationState,
} from '~/pages/admin/application_settings/metrics_and_profiling/usage_statistics';
import PayloadPreviewer from '~/pages/admin/application_settings/payload_previewer';
import initProductUsageData from '~/pages/admin/application_settings/metrics_and_profiling/product_usage_data';

export default () => {
  Array.from(document.querySelectorAll('.js-payload-preview-trigger')).forEach((trigger) => {
    new PayloadPreviewer(trigger).init();
  });
};

initSetHelperText();
initOptionMetricsState();
initUsagePingGenerationState();
initProductUsageData();
