import PayloadPreviewer from '~/pages/admin/application_settings/payload_previewer';

export default () => {
  Array.from(document.querySelectorAll('.js-payload-preview-trigger')).forEach(trigger => {
    new PayloadPreviewer(trigger).init();
  });
};
