import { DEFAULT_TH_CLASSES } from './constants';

/**
 * Generates the table header classes to be used for GlTable fields.
 *
 * @param {Number} width - The column width as a percentage.
 * @returns {String} The classes to be used in GlTable fields object.
 */
export const thWidthClass = (width) => `gl-w-${width}p ${DEFAULT_TH_CLASSES}`;
