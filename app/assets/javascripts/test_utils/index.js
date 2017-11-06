import 'core-js/es6/map';
import 'core-js/es6/set';
import simulateDrag from './simulate_drag';
import simulateInput from './simulate_input';

// Export to global space for rspec to use
window.simulateDrag = simulateDrag;
window.simulateInput = simulateInput;
