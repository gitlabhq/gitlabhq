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
      loadOnStart: false,
      theme: 'neutral',
    });

    $els.each((i, el) => {
      mermaid.init(undefined, el);
    });
  }).catch((err) => {
    Flash(`Can't load mermaid module: ${err}`);
  });
}
