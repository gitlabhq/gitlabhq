import Prism from 'prismjs';
import 'prismjs/components/prism-python';
import 'prismjs/plugins/custom-class/prism-custom-class';

Prism.plugins.customClass.map({
  comment: 'c',
  error: 'err',
  operator: 'o',
  constant: 'kc',
  namespace: 'kn',
  keyword: 'k',
  string: 's',
  number: 'm',
  'attr-name': 'na',
  builtin: 'nb',
  entity: 'ni',
  function: 'nf',
  tag: 'nt',
  variable: 'nv',
});

export default Prism;
