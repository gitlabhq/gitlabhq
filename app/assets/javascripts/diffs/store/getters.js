import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '../constants';

export const isParallelView = state => state.diffViewType === PARALLEL_DIFF_VIEW_TYPE;

export const isInlineView = state => state.diffViewType === INLINE_DIFF_VIEW_TYPE;

export const areAllFilesCollapsed = state => state.diffFiles.every(file => file.collapsed);

export const commitId = state => (state.commit && state.commit.id ? state.commit.id : null);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
