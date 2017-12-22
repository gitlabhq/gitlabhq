export default function initPathLocks(url, path) {
  $('a.path-lock').on('click', (e) => {
    e.preventDefault();

    $.post(url, {
      path,
    }, () => {
      location.reload();
    });
  });
}
