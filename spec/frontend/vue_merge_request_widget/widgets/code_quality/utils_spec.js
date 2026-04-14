import { SEVERITY_ICONS_MR_WIDGET } from '~/ci/reports/codequality_report/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  codeQualitySummary,
  transformNewCodeQualityFinding,
  transformResolvedCodeQualityFinding,
} from '~/vue_merge_request_widget/widgets/code_quality/utils';
import {
  newFinding,
  newFindingWithoutEngineName,
  resolvedFinding,
  resolvedFindingWithoutEngineName,
} from './mock_data';

describe('codeQualitySummary', () => {
  it.each`
    scenario                      | params                               | expected
    ${'both new and resolved'}    | ${{ newCount: 2, resolvedCount: 1 }} | ${'Code Quality scans found %{strong_start}2%{strong_end} new findings and %{strong_start}1%{strong_end} fixed finding.'}
    ${'only resolved (singular)'} | ${{ newCount: 0, resolvedCount: 1 }} | ${'Code Quality scans found %{strong_start}1%{strong_end} fixed finding.'}
    ${'only resolved (plural)'}   | ${{ newCount: 0, resolvedCount: 3 }} | ${'Code Quality scans found %{strong_start}3%{strong_end} fixed findings.'}
    ${'only new (singular)'}      | ${{ newCount: 1, resolvedCount: 0 }} | ${'Code Quality scans found %{strong_start}1%{strong_end} new finding.'}
    ${'only new (plural)'}        | ${{ newCount: 5, resolvedCount: 0 }} | ${'Code Quality scans found %{strong_start}5%{strong_end} new findings.'}
    ${'no changes'}               | ${{ newCount: 0, resolvedCount: 0 }} | ${"Code Quality hasn't changed."}
  `('returns correct text for $scenario', ({ params, expected }) => {
    expect(codeQualitySummary(params)).toBe(expected);
  });
});

describe('transformNewCodeQualityFinding', () => {
  describe('text', () => {
    it('returns text with severity, engine_name, and description', () => {
      const result = transformNewCodeQualityFinding(newFinding);

      expect(result.text).toBe(
        `${capitalizeFirstCharacter(newFinding.severity)} - ${newFinding.engine_name} - ${newFinding.description}`,
      );
    });

    it('omits engine_name from text when absent', () => {
      const result = transformNewCodeQualityFinding(newFindingWithoutEngineName);

      expect(result.text).toBe(
        `${capitalizeFirstCharacter(newFindingWithoutEngineName.severity)} - ${newFindingWithoutEngineName.description}`,
      );
    });
  });

  describe('icon', () => {
    it('maps severity to correct icon', () => {
      const result = transformNewCodeQualityFinding(newFinding);

      expect(result.icon.name).toBe(SEVERITY_ICONS_MR_WIDGET[newFinding.severity]);
    });
  });

  describe('link', () => {
    it('returns link with web_url and file path', () => {
      const result = transformNewCodeQualityFinding(newFinding);

      expect(result.link.href).toBe(newFinding.web_url);
      expect(result.link.text).toBe(`in ${newFinding.file_path}:${newFinding.line}`);
    });

    it('does not return badge or supportingText', () => {
      const result = transformNewCodeQualityFinding(newFinding);

      expect(result.badge).toBeUndefined();
      expect(result.supportingText).toBeUndefined();
    });
  });
});

describe('transformResolvedCodeQualityFinding', () => {
  describe('text', () => {
    it('returns text with severity, engine_name, and description', () => {
      const result = transformResolvedCodeQualityFinding(resolvedFinding);

      expect(result.text).toBe(
        `${capitalizeFirstCharacter(resolvedFinding.severity)} - ${resolvedFinding.engine_name} - ${resolvedFinding.description}`,
      );
    });

    it('omits engine_name from text when absent', () => {
      const result = transformResolvedCodeQualityFinding(resolvedFindingWithoutEngineName);

      expect(result.text).toBe(
        `${capitalizeFirstCharacter(resolvedFindingWithoutEngineName.severity)} - ${resolvedFindingWithoutEngineName.description}`,
      );
    });
  });

  describe('icon', () => {
    it('maps severity to correct icon', () => {
      const result = transformResolvedCodeQualityFinding(resolvedFinding);

      expect(result.icon.name).toBe('severityLow');
    });
  });

  describe('link', () => {
    it('returns supportingText with file path', () => {
      const result = transformResolvedCodeQualityFinding(resolvedFinding);

      expect(result.supportingText).toBe(`in ${resolvedFinding.file_path}:${resolvedFinding.line}`);
    });

    it('returns Fixed badge with neutral variant', () => {
      const result = transformResolvedCodeQualityFinding(resolvedFinding);

      expect(result.badge.text).toBe('Fixed');
      expect(result.badge.variant).toBe('neutral');
    });

    it('does not return link', () => {
      const result = transformResolvedCodeQualityFinding(resolvedFinding);

      expect(result.link).toBeUndefined();
    });
  });
});
