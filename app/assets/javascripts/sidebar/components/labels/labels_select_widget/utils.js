import { VARIANT_EMBEDDED, VARIANT_SIDEBAR, VARIANT_STANDALONE } from './constants';

/**
 * Returns boolean representing whether dropdown variant
 * is `sidebar`
 * @param {string} variant
 */
export const isDropdownVariantSidebar = (variant) => variant === VARIANT_SIDEBAR;

/**
 * Returns boolean representing whether dropdown variant
 * is `standalone`
 * @param {string} variant
 */
export const isDropdownVariantStandalone = (variant) => variant === VARIANT_STANDALONE;

/**
 * Returns boolean representing whether dropdown variant
 * is `embedded`
 * @param {string} variant
 */
export const isDropdownVariantEmbedded = (variant) => variant === VARIANT_EMBEDDED;
