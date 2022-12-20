import { DropdownVariant } from './constants';

/**
 * Returns boolean representing whether dropdown variant
 * is `sidebar`
 * @param {string} variant
 */
export const isDropdownVariantSidebar = (variant) => variant === DropdownVariant.Sidebar;

/**
 * Returns boolean representing whether dropdown variant
 * is `standalone`
 * @param {string} variant
 */
export const isDropdownVariantStandalone = (variant) => variant === DropdownVariant.Standalone;

/**
 * Returns boolean representing whether dropdown variant
 * is `embedded`
 * @param {string} variant
 */
export const isDropdownVariantEmbedded = (variant) => variant === DropdownVariant.Embedded;
