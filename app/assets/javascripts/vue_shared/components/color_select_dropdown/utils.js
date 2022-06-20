import { DROPDOWN_VARIANT } from './constants';

/**
 * Returns boolean representing whether dropdown variant
 * is `sidebar`
 * @param {string} variant
 */
export const isDropdownVariantSidebar = (variant) => variant === DROPDOWN_VARIANT.Sidebar;

/**
 * Returns boolean representing whether dropdown variant
 * is `embedded`
 * @param {string} variant
 */
export const isDropdownVariantEmbedded = (variant) => variant === DROPDOWN_VARIANT.Embedded;
