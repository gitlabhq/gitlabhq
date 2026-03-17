import { formatProjectSourcesMessage } from '~/homepage/utils/format_project_sources_message';
import {
  PROJECT_SOURCE_FRECENT,
  PROJECT_SOURCE_STARRED,
  PROJECT_SOURCE_PERSONAL,
} from '~/homepage/constants';

describe('formatProjectSourcesMessage', () => {
  it('returns default message when no sources are selected', () => {
    expect(formatProjectSourcesMessage([])).toBe('Displaying projects.');
  });

  it('returns message for single source', () => {
    expect(formatProjectSourcesMessage([PROJECT_SOURCE_FRECENT])).toBe(
      'Displaying frequently visited projects.',
    );
  });

  it('returns message for two sources', () => {
    expect(formatProjectSourcesMessage([PROJECT_SOURCE_FRECENT, PROJECT_SOURCE_STARRED])).toBe(
      'Displaying frequently visited and starred projects.',
    );
  });

  it('returns message for three sources with Oxford comma', () => {
    expect(
      formatProjectSourcesMessage([
        PROJECT_SOURCE_FRECENT,
        PROJECT_SOURCE_STARRED,
        PROJECT_SOURCE_PERSONAL,
      ]),
    ).toBe('Displaying frequently visited, starred, and personal projects.');
  });

  it('handles sources in any order', () => {
    expect(formatProjectSourcesMessage([PROJECT_SOURCE_PERSONAL, PROJECT_SOURCE_FRECENT])).toBe(
      'Displaying personal and frequently visited projects.',
    );
  });
});
