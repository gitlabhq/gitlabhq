// Counts the Mermaid diagrams a page has auto-rendered. This module imports
// nothing, so the Vue 3 build never duplicates it and both Vue lanes share
// one count against the page-wide limit.

let renderedMermaidBlocks = 0;

export const getRenderedMermaidBlocks = () => renderedMermaidBlocks;

export const incrementRenderedMermaidBlocks = () => {
  renderedMermaidBlocks += 1;
};
