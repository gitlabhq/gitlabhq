import { editor } from 'monaco-editor';
import { Sortable } from 'sortablejs';
import simulateDrag from './simulate_drag';

// Export to global space for rspec to use
window.localMonaco = editor;
window.simulateDrag = simulateDrag;
window.Sortable = Sortable;
