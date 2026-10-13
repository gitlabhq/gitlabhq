import {
  accessibilityErrorCount,
  accessibilitySummaryText,
  accessibilitySections,
  accessibilityWidgetItems,
} from '~/vue_merge_request_widget/widgets/accessibility/utils';

describe('accessibility widget utils', () => {
  const error = (code) => ({ code, message: 'Something is wrong' });

  // The endpoint answers with an empty body while the report is still parsing.
  it.each(['', undefined, {}])('tolerates %p', (data) => {
    expect(accessibilityErrorCount(data)).toBe(0);
    expect(accessibilitySections(data)).toEqual([]);
  });

  it('counts the errored total from the summary', () => {
    expect(accessibilityErrorCount({ summary: { errored: 3 } })).toBe(3);
  });

  it.each([
    [0, 'Accessibility scanning detected no issues for the source branch only'],
    [
      1,
      'Accessibility scanning detected %{strong_start}1%{strong_end} issue for the source branch only',
    ],
    [
      5,
      'Accessibility scanning detected %{strong_start}5%{strong_end} issues for the source branch only',
    ],
  ])('summarises %i errors', (errorCount, expected) => {
    expect(accessibilitySummaryText(errorCount)).toBe(expected);
  });

  it('drops empty groups and transforms each error', () => {
    expect(
      accessibilitySections({
        new_errors: [],
        existing_errors: [error('WCAG2AA.Principle1.Guideline1_1.1_1_1.H37')],
        resolved_errors: [error('WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2')],
      }),
    ).toEqual([
      {
        header: 'Not fixed',
        children: [
          {
            text: 'The accessibility scanning found an error of the following type: WCAG2AA.Principle1.Guideline1_1.1_1_1.H37',
            icon: { name: 'failed' },
            supportingText: 'Message: Something is wrong',
            actions: [
              {
                text: 'Details',
                icon: 'external-link',
                href: 'https://www.w3.org/TR/WCAG20-TECHS/H37.html',
                target: '_blank',
                rel: 'noopener noreferrer',
                variant: 'link',
              },
            ],
          },
        ],
      },
      {
        header: 'Fixed',
        children: [
          expect.objectContaining({
            icon: { name: 'success' },
            actions: [
              expect.objectContaining({ href: 'https://www.w3.org/TR/WCAG20-TECHS/H30.html' }),
            ],
          }),
        ],
      },
    ]);
  });

  it.each(['WCAG2AA.Principle1.Guideline1_1.1_1_1', undefined])(
    'links to the W3C overview for code %p',
    (code) => {
      const [section] = accessibilitySections({ new_errors: [error(code)] });

      expect(section.children[0].actions[0].href).toBe(
        'https://www.w3.org/TR/WCAG20-TECHS/Overview.html',
      );
    },
  );

  it('flattens sections, heading only the first row of each group', () => {
    const items = accessibilityWidgetItems({
      new_errors: [error('a.b.c.d.H1'), error('a.b.c.d.H2')],
      resolved_errors: [error('a.b.c.d.H3')],
    });

    expect(items.map(({ header }) => header)).toEqual(['New', '', 'Fixed']);
  });
});
