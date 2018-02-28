export default class GpgBadges {
  static fetch() {
    const form = $('.commits-search-form');

    $.get({
      url: form.data('signatures-path'),
      data: form.serialize(),
    }).done((response) => {
      const badges = $('.js-loading-gpg-badge');
      response.signatures.forEach((signature) => {
        badges.filter(`[data-commit-sha="${signature.commit_sha}"]`).replaceWith(signature.html);
      });
    });
  }
}
