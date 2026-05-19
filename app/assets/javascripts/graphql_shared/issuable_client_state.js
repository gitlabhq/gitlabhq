import { makeVar } from '@apollo/client/core';

/**
 * Note: For Vue 3 migration compatibility these variables should be declared on their own module.
 *
 * This file should not import Vue, VueApollo, or other dependencies that may cause a duplication
 * as these variables could share state between Vue 2 and Vue 3 applications.
 */
export const linkedItems = makeVar({});
export const currentAssignees = makeVar({});
export const currentReviewers = makeVar([]);
export const appliedLabels = makeVar([]);
export const availableStatuses = makeVar({});
export const supportedConversionTypes = makeVar({});
