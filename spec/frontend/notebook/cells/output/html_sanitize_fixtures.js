/**
 * Jupyter notebooks handles the following data types
 * that are to be handled by `html.vue`
 *
 * 'text/html';
 * 'image/svg+xml';
 *
 * This file sets up fixtures for each of these types
 * NOTE: The inputs are taken directly from data derived from the
 * jupyter notebook file used to test nbview here:
 * https://nbviewer.jupyter.org/github/ipython/ipython-in-depth/blob/master/examples/IPython%20Kernel/Rich%20Output.ipynb
 */

export default [
  [
    'text/html table',
    {
      input: [
        '<style type="text/css">\n',
        '\n',
        'body {\n',
        '  background: red;\n',
        '}\n',
        '\n',
        '</style>\n',
        '<table data-myattr="XSS">\n',
        '<tr>\n',
        '<th>Header 1</th>\n',
        '<th>Header 2</th>\n',
        '</tr>\n',
        '<tr>\n',
        '<td style="background: red;">row 1, cell 1</td>\n',
        '<td>row 1, cell 2</td>\n',
        '</tr>\n',
        '<tr>\n',
        '<td>row 2, cell 1</td>\n',
        '<td>row 2, cell 2</td>\n',
        '</tr>\n',
        '</table>',
      ].join(''),
      output: '<table data-myattr=&quot;XSS&quot;>',
    },
  ],
  // Note: style is sanitized out
  [
    'text/html style',
    {
      input: [
        '<style type="text/css">\n',
        '\n',
        'circle {\n',
        '  fill: rgb(31, 119, 180);\n',
        '  fill-opacity: .25;\n',
        '  stroke: rgb(31, 119, 180);\n',
        '  stroke-width: 1px;\n',
        '}\n',
        '\n',
        '.leaf circle {\n',
        '  fill: #ff7f0e;\n',
        '  fill-opacity: 1;\n',
        '}\n',
        '\n',
        'text {\n',
        '  font: 10px sans-serif;\n',
        '}\n',
        '\n',
        '</style>',
      ].join(''),
      output: '<!---->',
    },
  ],
  // Note: iframe is sanitized out
  [
    'text/html iframe',
    {
      input: [
        '\n',
        '        <iframe\n',
        '            width="400"\n',
        '            height="300"\n',
        '            src="https://www.youtube.com/embed/sjfsUzECqK0"\n',
        '            frameborder="0"\n',
        '            allowfullscreen\n',
        '        ></iframe>\n',
        '        ',
      ].join(''),
      output: '<!---->',
    },
  ],
  [
    'image/svg+xml',
    {
      input: [
        '<svg height="115.02pt" id="svg2" version="1.0" width="388.84pt" xmlns="http://www.w3.org/2000/svg">\n',
        '  <g>\n',
        '    <path d="M 184.61344,61.929363 C 184.61344,47.367213 180.46118,39.891193 172.15666,39.481813" style="fill:#646464;fill-opacity:1"/>\n',
        '  </g>\n',
        '</svg>',
      ].join(),
      output:
        '<svg height=&quot;115.02pt&quot; id=&quot;svg2&quot; version=&quot;1.0&quot; width=&quot;388.84pt&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;>',
    },
  ],
];
