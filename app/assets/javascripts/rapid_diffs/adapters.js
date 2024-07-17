import { ExpandLinesAdapter } from '~/rapid_diffs/expand_lines/adapter';

/** @module RapidDiffs */

const RAPID_DIFFS_VIEWERS = {
  text_inline: 'text_inline',
  text_parallel: 'text_parallel',
};

export const VIEWER_ADAPTERS = {
  [RAPID_DIFFS_VIEWERS.text_inline]: [ExpandLinesAdapter],
  [RAPID_DIFFS_VIEWERS.text_parallel]: [ExpandLinesAdapter],
};

/** @typedef {HTMLDivElement} diffElement */
/** @typedef {string} viewer */

/**
 * @typedef {Object} adapterContext
 * @property {viewer} viewer
 * @property {diffElement} diffElement
 */

/**
 * @typedef {PointerEvent} PointerEventWithTarget
 * @property {HTMLElement} target
 */

/**
 * @typedef {Object} diffFileAdapter
 * @property {function(this: adapterContext, event: PointerEventWithTarget): void} [onClick] - Handle click events that happen on the diff file.
 * @property {function(this: adapterContext): void} [onVisible] - Executes when diff files becomes visible.
 * @property {function(this: adapterContext): void} [onInvisible] - Executes when diff files becomes invisible.
 */
