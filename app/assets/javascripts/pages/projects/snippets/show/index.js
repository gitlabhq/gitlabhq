import '~/snippet/snippet_show';

const awardEmojiEl = document.getElementById('js-vue-awards-block');

if (awardEmojiEl) {
  import('~/emoji/awards_app')
    .then((m) => m.default(awardEmojiEl))
    .catch(() => {});
}
