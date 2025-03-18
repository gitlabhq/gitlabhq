import { ALERT_TYPES, DEFAULT_ALERT_TITLES } from '~/content_editor/constants/alert_types';
import { serialize, builders } from '../../serialization_utils';

const { alert, alertTitle } = builders;

describe('content_editor/services/serializer/alert_title', () => {
  it('correctly serializes alert titles with default content', () => {
    expect(serialize(alert(alertTitle()))).toBe('> [!note]');

    expect(serialize(alert(alertTitle('Note')))).toBe('> [!note]');
  });

  it('correctly serializes alert titles with custom content', () => {
    expect(serialize(alert(alertTitle('Custom Title')))).toBe('> [!note] Custom Title');
  });

  it('correctly serializes alert titles for different alert types', () => {
    Object.values(ALERT_TYPES).forEach((type) => {
      expect(serialize(alert({ type }, alertTitle()))).toBe(`> [!${type}]`);
    });
  });

  it('correctly serializes alert titles with custom content for different alert types', () => {
    Object.values(ALERT_TYPES).forEach((type) => {
      expect(serialize(alert({ type }, alertTitle('Custom Title')))).toBe(
        `> [!${type}] Custom Title`,
      );
    });
  });

  it('does not duplicate default title when custom title matches default', () => {
    Object.values(ALERT_TYPES).forEach((type) => {
      expect(serialize(alert({ type }, alertTitle(DEFAULT_ALERT_TITLES[type])))).toBe(
        `> [!${type}]`,
      );
    });
  });
});
