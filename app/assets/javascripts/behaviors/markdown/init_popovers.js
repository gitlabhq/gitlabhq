// Lazily initialize reference popovers (issues, work items, merge requests,
// milestones, commits, ...) for the given elements.
export default function initPopovers(elements) {
  if (!elements.length) return;

  import(/* webpackChunkName: 'IssuablePopoverBundle' */ '~/issuable/popover')
    .then(({ default: initIssuablePopovers }) => {
      initIssuablePopovers(elements);
    })
    .catch(() => {});
}
