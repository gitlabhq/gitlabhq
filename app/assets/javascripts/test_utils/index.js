import { editor } from 'monaco-editor';
import { Sortable } from 'sortablejs';
import simulateDrag from './simulate_drag';
import simulateInput from './simulate_input';

// Export to global space for rspec to use
window.localMonaco = editor;
window.simulateDrag = simulateDrag;
window.simulateInput = simulateInput;
window.Sortable = Sortable;
