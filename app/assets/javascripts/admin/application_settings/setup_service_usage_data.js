import PayloadPreviewer from '~/pages/admin/application_settings/payload_previewer';
import PayloadDownloader from '~/pages/admin/application_settings/payload_downloader';

export default () => {
  const payloadPreviewTrigger = document.querySelector('.js-payload-preview-trigger');
  const payloadDownloadTrigger = document.querySelector('.js-payload-download-trigger');

  if (payloadPreviewTrigger) {
    new PayloadPreviewer(payloadPreviewTrigger).init();
  }

  if (payloadDownloadTrigger) {
    new PayloadDownloader(payloadDownloadTrigger).init();
  }
};
