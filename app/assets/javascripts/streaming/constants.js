// Lower min chunk numbers can make the page loading take incredibly long
export const MIN_CHUNK_SIZE = 128 * 1024;
export const MAX_CHUNK_SIZE = 2048 * 1024;
export const LOW_FRAME_TIME = 32;
// Tasks that take more than 50ms are considered Long
// https://web.dev/optimize-long-tasks/
export const HIGH_FRAME_TIME = 64;
export const BALANCE_RATE = 1.2;
export const TIMEOUT = 100;
