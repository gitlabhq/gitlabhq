import mermaid from 'mermaid-v11';
import elkLayouts from '@mermaid-js/layout-elk';
import { initMermaidSandbox } from './mermaid_sandbox';

mermaid.registerLayoutLoaders(elkLayouts);
initMermaidSandbox(mermaid);
