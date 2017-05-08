import simulateDrag from './simulate_drag';
import globalErrorHandler from './global_error_handler';

// Export to global space for rspec to use
window.simulateDrag = simulateDrag;

globalErrorHandler();
