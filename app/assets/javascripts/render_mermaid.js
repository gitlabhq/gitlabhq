/* eslint-disable func-names */

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

$.fn.renderMermaid = function () {
  if (this.length === 0) return;

  import(/* webpackChunkName: 'mermaid' */ 'mermaid').then((mermaid) => {
    mermaid.initialize({
      loadOnStart: false,
    });

    mermaid.init(undefined, this);
  }).catch((err) => {
    Flash(`Can't load mermaid module: ${err}`);
  });
};
