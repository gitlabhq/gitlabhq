import mermaid from 'mermaid-v12';
import { initMermaidSandbox } from './mermaid_sandbox';

const v11NodeSizing = { minNodeWidth: 0, wrappingWidth: 200 };

initMermaidSandbox(mermaid, {
  look: 'classic',
  flowchart: { layout: 'dagre', ...v11NodeSizing },
  state: { layout: 'dagre', ...v11NodeSizing },
  class: { layout: 'dagre' },
  er: { layout: 'dagre' },
  requirement: { layout: 'dagre' },
});
