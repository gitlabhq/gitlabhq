import { getLocationHash } from '~/lib/utils/url_utility';
import { NOTE_UNDERSCORE } from '~/notes/constants';

export function getNoteIdFromHash() {
  const hash = getLocationHash();
  if (!hash?.startsWith(NOTE_UNDERSCORE)) return null;
  return hash.substring(NOTE_UNDERSCORE.length) || null;
}

export function discussionsContainNote(discussions, noteId) {
  return discussions.some((d) => d.notes?.some((n) => String(n.id) === noteId));
}
