export default function conditionallyLoadProjectDropdown() {
  const el = document.getElementById('js-projects-dropdown');
  const navEl = document.getElementById('nav-projects-dropdown');
  if (!el || !navEl) {
    return;
  }
  $(navEl).one('show.bs.dropdown', (e) => {
    import(/* webpackChunkName: 'projects_dropdown' */ './projects_dropdown')
    .then((importedFunc) => {
      importedFunc.default(e);
    })
    .catch(() => {});
  });
}
