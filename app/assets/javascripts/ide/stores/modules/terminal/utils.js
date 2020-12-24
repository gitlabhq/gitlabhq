import { STARTING, PENDING, RUNNING } from './constants';

export const isStartingStatus = (status) => status === STARTING || status === PENDING;
export const isRunningStatus = (status) => status === RUNNING;
export const isEndingStatus = (status) => !isStartingStatus(status) && !isRunningStatus(status);
