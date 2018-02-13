export default () => {
  $('#modal-delete-domain').on('show.bs.modal', (event) => {
    const button = $(event.relatedTarget);
    const domainName = button.data('domain');
    const domainDeleteUrl = button.data('domainurl');
    const modal = $('#modal-delete-domain');
    modal.find('.page-title').text(`Remove ${domainName}?`);
    modal.find('#domain-name-field').text(domainName);
    modal.find('#domain-delete-link').attr('href', domainDeleteUrl);
  });
};
