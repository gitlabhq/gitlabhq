export default class GpgBadges {
  static fetch() {
    const badges = $('.js-loading-gpg-badge');
    const form = $('.commits-search-form');

    badges.html('<i class="fa fa-spinner fa-spin"></i>');

    $.get({
      url: form.data('signatures-path'),
      data: form.serialize(),
    }).done((response) => {
      response.signatures.forEach((signature) => {
        badges.filter(`[data-commit-sha="${signature.commit_sha}"]`).replaceWith(signature.html);
      });
    });
  }
}
