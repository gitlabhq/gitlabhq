import { marked } from 'marked';
import markedBidi from 'marked-bidi';
import { sanitize } from '~/lib/dompurify';
import { markdownConfig } from '~/lib/utils/text_utility';

/**
 * Tracks snowplow event when User toggles timeline view
 * @param {Boolean} enabled that will be send as a property for the event
 */
export const trackToggleTimelineView = (enabled) => ({
  category: 'Incident Management', // eslint-disable-line @gitlab/require-i18n-strings
  action: 'toggle_incident_comments_into_timeline_view',
  label: 'Status', // eslint-disable-line @gitlab/require-i18n-strings
  property: enabled,
});

marked.use(markedBidi());

export const renderMarkdown = (rawMarkdown) => {
  return sanitize(marked(rawMarkdown), markdownConfig);
};
