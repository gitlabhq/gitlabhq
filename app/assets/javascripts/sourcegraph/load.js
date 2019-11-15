import initSourcegraph from './index';

/**
 * Load sourcegraph in it's own listener so that it's isolated from failures.
 */
document.addEventListener('DOMContentLoaded', initSourcegraph);
