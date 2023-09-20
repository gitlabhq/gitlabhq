import { mountExtended } from 'helpers/vue_test_utils_helper';
import InlineFindings from '~/diffs/components/inline_findings.vue';
import DiffInlineFindings from '~/diffs/components/diff_inline_findings.vue';
import { NEW_CODE_QUALITY_FINDINGS } from '~/diffs/i18n';
import { threeCodeQualityFindings } from '../mock_data/inline_findings';

let wrapper;

const diffInlineFindings = () => wrapper.findComponent(DiffInlineFindings);

describe('InlineFindings', () => {
  const createWrapper = () => {
    return mountExtended(InlineFindings, {
      propsData: {
        codeQuality: threeCodeQualityFindings,
      },
    });
  };

  it('hides details and throws hideInlineFindings event on close click', async () => {
    wrapper = createWrapper();
    expect(wrapper.findByTestId('inline-findings').exists()).toBe(true);

    await wrapper.findByTestId('inline-findings-close').trigger('click');
    expect(wrapper.emitted('hideInlineFindings')).toHaveLength(1);
  });

  it('renders diff inline findings component with correct props for codequality array', () => {
    wrapper = createWrapper();
    expect(diffInlineFindings().props('title')).toBe(NEW_CODE_QUALITY_FINDINGS);
    expect(diffInlineFindings().props('findings')).toBe(threeCodeQualityFindings);
  });
});
