import { LOADING, ERROR, SUCCESS } from '../constants';

export const reports = state => state.reports;
export const summaryCounts = state => state.summary;
export const isLoading = state => state.isLoading;
export const hasError = state => state.hasError;
export const modalTitle = state => state.modal.title || '';
export const modalData = state => state.modal.data || {};
export const isCreatingNewIssue = state => state.modal.isLoading;

export const summaryStatus = state => {
  if (state.isLoading) {
    return LOADING;
  }

  if (state.hasError) {
    return ERROR;
  }

  return SUCCESS;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
