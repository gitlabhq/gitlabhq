/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueGlPagination = Vue.extend({
    props: [
      'changepage',
      'pages',
    ],
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix">
          <li class="prev disabled">
            <span>Prev</span>
          </li>
          <li class="page active">
            <a @click='changepage($event)'>1</a>
          </li>
          <li class="page">
            <a
              rel="next"
              @click='changepage($event)'
            >
              2
            </a>
          </li>
          <li class="page">
            <a @click='changepage($event)'>3</a>
          </li>
          <li class="page">
            <a @click='changepage($event)'>4</a>
          </li>
          <li class="page">
            <a @click='changepage($event)'>5</a>
          </li>
          <li class="page">
            <span class="page gap">…</span>
          </li>
          <li class="next">
            <a
              rel="next"
              href="pipelines?page=2"
            >
              Next
            </a>
          </li>
          <li class="last">
            <a href="pipelines?page=936">Last »</a>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
