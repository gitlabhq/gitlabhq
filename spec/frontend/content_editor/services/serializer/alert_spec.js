import { ALERT_TYPES } from '~/content_editor/constants/alert_types';
import { serialize, builders } from '../../serialization_utils';

const { paragraph, alert, alertTitle, codeBlock, bold } = builders;

describe('content_editor/services/serializer/alert', () => {
  it('correctly serializes alerts with default type', () => {
    expect(serialize(alert(alertTitle(), paragraph('This is a note')))).toBe(
      `> [!note]
>
> This is a note`,
    );
  });

  it('correctly serializes alerts with specified type', () => {
    expect(
      serialize(alert({ type: ALERT_TYPES.WARNING }, alertTitle(), paragraph('This is a warning'))),
    ).toBe(
      `> [!warning]
>
> This is a warning`,
    );
  });

  it('correctly serializes alerts with multiple block nodes', () => {
    expect(
      serialize(
        alert(
          alertTitle('Note title'),
          paragraph('First paragraph'),
          codeBlock('var x = 10;'),
          paragraph('Second paragraph'),
        ),
      ),
    ).toBe(
      `> [!note] Note title
>
> First paragraph
>
> \`\`\`
> var x = 10;
> \`\`\`
>
> Second paragraph`,
    );
  });

  it('correctly serializes alerts with formatted content', () => {
    expect(
      serialize(alert(alertTitle(), paragraph('This is ', bold('very important'), ' information'))),
    ).toBe(
      `> [!note]
>
> This is **very important** information`,
    );
  });
});
