<script>
import { s__ } from '~/locale';

export default {
  computed: {
    themeClass() {
      return window.gon?.user_color_scheme;
    },
  },
  i18n: {
    previewLabel: s__('Preferences|Preview'),
  },
};
</script>
<template>
  <div class="form-group">
    <label>{{ $options.i18n.previewLabel }}</label>
    <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
    <table :class="themeClass" class="code">
      <tbody>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="1"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span
              ><span class="c1"># <span class="idiff deletion">Removed</span> content</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="1"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span
              ><span class="c1"># <span class="idiff addition">Added</span> content</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="2"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span><span class="n">v</span> <span class="o">=</span> <span class="mi">1</span></span>
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="2"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span><span class="n">v</span> <span class="o">=</span> <span class="mi">1</span></span>
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="3"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span
              ><span class="n">s</span> <span class="o">=</span>
              <span class="s">"string"</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="3"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span
              ><span class="n">s</span> <span class="o">=</span>
              <span class="s">"string"</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="4"></a>
          </td>
          <td class="line_content parallel left-side old"><span></span></td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="4"></a>
          </td>
          <td class="line_content parallel right-side new"><span></span></td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="5"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span
              ><span class="k">for</span> <span class="n">i</span> <span class="ow">in</span>
              <span class="nb">range</span><span class="p">(</span><span class="o">-</span
              ><span class="mi">10</span><span class="p">,</span> <span class="mi">10</span
              ><span class="p">):</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="5"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span
              ><span class="k">for</span> <span class="n">i</span> <span class="ow">in</span>
              <span class="nb">range</span><span class="p">(</span><span class="o">-</span
              ><span class="mi">10</span><span class="p">,</span> <span class="mi">10</span
              ><span class="p">):</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="6"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span>
              <span>{{ '    ' }}</span
              ><span class="k">print</span><span class="p">(</span><span class="n">i</span>
              <span class="o">+</span> <span class="mi">1</span><span class="p">)</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="6"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span>
              <span>{{ '    ' }}</span
              ><span class="k">print</span><span class="p">(</span><span class="n">i</span>
              <span class="o">+</span> <span class="mi">1</span><span class="p">)</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="7"></a>
          </td>
          <td class="line_content parallel left-side old"><span></span></td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="7"></a>
          </td>
          <td class="line_content parallel right-side new"><span></span></td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="8"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span
              ><span class="k">class</span> <span class="nc">LinkedList</span
              ><span class="p">(</span><span class="nb">object</span><span class="p">):</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="8"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span
              ><span class="k">class</span> <span class="nc">LinkedList</span
              ><span class="p">(</span><span class="nb">object</span><span class="p">):</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="9"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span>
              <span>{{ '    ' }}</span
              ><span class="k">def</span> <span class="nf">__init__</span><span class="p">(</span
              ><span class="bp">self</span><span class="p">,</span> <span class="n">x</span
              ><span class="p">):</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="9"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span>
              <span>{{ '    ' }}</span
              ><span class="k">def</span> <span class="nf">__init__</span><span class="p">(</span
              ><span class="bp">self</span><span class="p">,</span> <span class="n">x</span
              ><span class="p">):</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="10"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span>
              <span>{{ '        ' }}</span
              ><span class="bp">self</span><span class="p">.</span><span class="n">val</span>
              <span class="o">=</span> <span class="n">x</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="10"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span>
              <span>{{ '        ' }}</span
              ><span class="bp">self</span><span class="p">.</span><span class="n">val</span>
              <span class="o">=</span> <span class="n">x</span></span
            >
          </td>
        </tr>
        <tr class="line_holder parallel">
          <td class="old_line diff-line-num old">
            <a data-linenumber="11"></a>
          </td>
          <td class="line_content parallel left-side old">
            <span>
              <span>{{ '        ' }}</span
              ><span class="bp">self</span><span class="p">.</span><span class="nb">next</span>
              <span class="o">=</span> <span class="bp">None</span></span
            >
          </td>
          <td class="new_line diff-line-num new">
            <a data-linenumber="11"></a>
          </td>
          <td class="line_content parallel right-side new">
            <span>
              <span>{{ '        ' }}</span
              ><span class="bp">self</span><span class="p">.</span><span class="nb">next</span>
              <span class="o">=</span> <span class="bp">None</span></span
            >
          </td>
        </tr>
      </tbody>
    </table>
    <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
  </div>
</template>
