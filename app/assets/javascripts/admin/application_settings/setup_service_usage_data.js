import PayloadPreviewer from '~/pages/admin/application_settings/payload_previewer';

export default () => {
  const payloadPreviewTrigger = document.querySelector('.js-payload-preview-trigger');

  if (payloadPreviewTrigger) {
    new PayloadPreviewer(payloadPreviewTrigger).init();
  }
};
