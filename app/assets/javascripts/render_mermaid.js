// Renders diagrams and flowcharts from text using Mermaid in any element with the
// `js-render-mermaid` class.
//
// Example markup:
//
// <pre class="js-render-mermaid">
//  graph TD;
//    A-- > B;
//    A-- > C;
//    B-- > D;
//    C-- > D;
// </pre>
//

import Flash from './flash';

export default function renderMermaid($els) {
  if (!$els.length) return;

  import(/* webpackChunkName: 'mermaid' */ 'blackst0ne-mermaid').then((mermaid) => {
    mermaid.initialize({
      // mermaid core options
      mermaid: {
        startOnLoad: false,
      },
      // mermaidAPI options
      theme: 'neutral',
    });

    $els.each((i, el) => {
      // Handle a condition that happens in CI and some of the time locally,
      // where the `textContent` is the content of the styles injected by
      // Mermaid, as well as any labels.
      if (el.querySelector('style')) { return; }

      const source = el.textContent;

      // Remove any extra spans added by the backend syntax highlighting.
      Object.assign(el, { textContent: source });

      mermaid.init(undefined, el);
    });
  }).catch((err) => {
    Flash(`Can't load mermaid module: ${err}`);
  });
}
