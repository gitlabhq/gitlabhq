/* eslint-disable @gitlab/require-i18n-strings */
import marked from 'marked';
import { sanitize } from '~/lib/dompurify';
import { markdownConfig } from '~/lib/utils/text_utility';

/**
 * Tracks snowplow event when User toggles timeline view
 * @param {Boolean} enabled that will be send as a property for the event
 */
export const trackToggleTimelineView = (enabled) => ({
  category: 'Incident Management',
  action: 'toggle_incident_comments_into_timeline_view',
  label: 'Status',
  property: enabled,
});

export const renderMarkdown = (rawMarkdown) => {
  return sanitize(marked(rawMarkdown), markdownConfig);
};
