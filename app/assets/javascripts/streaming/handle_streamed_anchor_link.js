import { throttle } from 'lodash';
import { scrollToElement } from '~/lib/utils/common_utils';
import LineHighlighter from '~/blob/line_highlighter';

const noop = () => {};

export function handleStreamedAnchorLink(rootElement) {
  // "#L100-200" → ['L100', 'L200']
  const [anchorStart, end] = window.location.hash.substring(1).split('-');
  const anchorEnd = end ? `L${end}` : anchorStart;
  if (!anchorStart || document.getElementById(anchorEnd)) return noop;

  const handler = throttle((mutationList, instance) => {
    if (!document.getElementById(anchorEnd)) return;
    scrollToElement(document.getElementById(anchorStart));
    // eslint-disable-next-line no-new
    new LineHighlighter();
    instance.disconnect();
  }, 300);

  const observer = new MutationObserver(handler);

  observer.observe(rootElement, { childList: true, subtree: true });

  return () => observer.disconnect();
}
