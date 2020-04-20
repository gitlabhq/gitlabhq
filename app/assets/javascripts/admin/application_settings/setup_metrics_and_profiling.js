import PayloadPreviewer from '~/pages/admin/application_settings/payload_previewer';

export default () => {
  new PayloadPreviewer(
    document.querySelector('.js-usage-ping-payload-trigger'),
    document.querySelector('.js-usage-ping-payload'),
  ).init();
};
