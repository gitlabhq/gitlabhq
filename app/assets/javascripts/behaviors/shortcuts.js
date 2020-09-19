export default function initPageShortcuts() {
  const { page } = document.body.dataset;
  const pagesWithCustomShortcuts = [
    'projects:activity',
    'projects:artifacts:browse',
    'projects:artifacts:file',
    'projects:blame:show',
    'projects:blob:show',
    'projects:commit:show',
    'projects:commits:show',
    'projects:find_file:show',
    'projects:issues:edit',
    'projects:issues:index',
    'projects:issues:new',
    'projects:issues:show',
    'projects:merge_requests:creations:diffs',
    'projects:merge_requests:creations:new',
    'projects:merge_requests:edit',
    'projects:merge_requests:index',
    'projects:merge_requests:show',
    'projects:network:show',
    'projects:show',
    'projects:tree:show',
    'groups:show',
  ];

  // the pages above have their own shortcuts sub-classes instantiated elsewhere
  // TODO: replace this whitelist with something more automated/maintainable
  if (page && !pagesWithCustomShortcuts.includes(page)) {
    import(/* webpackChunkName: 'shortcutsBundle' */ './shortcuts/shortcuts')
      .then(({ default: Shortcuts }) => new Shortcuts())
      .catch(() => {});
  }
  return false;
}
