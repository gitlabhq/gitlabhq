// Lower min chunk numbers can make the page loading take incredibly long
export const MIN_CHUNK_SIZE = 128 * 1024;
// A large ceiling lets the balancer write big chunks (fewer tasks, less overhead,
// faster total load). The Scheduler API yields to user input between tasks, so
// this stays responsive while streaming; benchmarked as the sweet spot.
export const MAX_CHUNK_SIZE = 8192 * 1024;
export const LOW_FRAME_TIME = 32;
// Tasks that take more than 50ms are considered Long
// https://web.dev/optimize-long-tasks/
export const HIGH_FRAME_TIME = 64;
export const BALANCE_RATE = 1.2;
export const TIMEOUT = 100;
