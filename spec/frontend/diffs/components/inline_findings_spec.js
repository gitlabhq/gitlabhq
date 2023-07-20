import { mountExtended } from 'helpers/vue_test_utils_helper';
import InlineFindings from '~/diffs/components/inline_findings.vue';
import DiffInlineFindings from '~/diffs/components/diff_inline_findings.vue';
import { NEW_CODE_QUALITY_FINDINGS, NEW_SAST_FINDINGS } from '~/diffs/i18n';
import { multipleCodeQualityNoSast, multipleSastNoCodeQuality } from '../mock_data/inline_findings';

let wrapper;

const diffInlineFindings = () => wrapper.findComponent(DiffInlineFindings);
const allDiffInlineFindings = () => wrapper.findAllComponents(DiffInlineFindings);

describe('InlineFindings', () => {
  const createWrapper = (findings) => {
    return mountExtended(InlineFindings, {
      propsData: {
        expandedLines: [],
        codeQuality: findings.codeQuality,
        sast: findings.sast,
      },
    });
  };

  it('hides details and throws hideInlineFindings event on close click', async () => {
    wrapper = createWrapper(multipleCodeQualityNoSast);
    expect(wrapper.findByTestId('inline-findings').exists()).toBe(true);

    await wrapper.findByTestId('inline-findings-close').trigger('click');
    expect(wrapper.emitted('hideInlineFindings')).toHaveLength(1);
  });

  it('renders diff inline findings component with correct props for codequality array', () => {
    wrapper = createWrapper(multipleCodeQualityNoSast);

    expect(diffInlineFindings().props('title')).toBe(NEW_CODE_QUALITY_FINDINGS);
    expect(diffInlineFindings().props('findings')).toBe(multipleCodeQualityNoSast.codeQuality);
  });

  it('does not render codeQuality section when codeQuality array is empty', () => {
    wrapper = createWrapper(multipleSastNoCodeQuality);

    expect(diffInlineFindings().props('title')).toBe(NEW_SAST_FINDINGS);
    expect(allDiffInlineFindings()).toHaveLength(1);
  });

  it('renders heading and correct amount of list items for sast array and their description', () => {
    wrapper = createWrapper(multipleSastNoCodeQuality);

    expect(diffInlineFindings().props('title')).toBe(NEW_SAST_FINDINGS);
    expect(diffInlineFindings().props('findings')).toBe(multipleSastNoCodeQuality.sast);
  });

  it('does not render sast section when sast array is empty', () => {
    wrapper = createWrapper(multipleCodeQualityNoSast);

    expect(diffInlineFindings().props('title')).toBe(NEW_CODE_QUALITY_FINDINGS);
    expect(allDiffInlineFindings()).toHaveLength(1);
  });
});
