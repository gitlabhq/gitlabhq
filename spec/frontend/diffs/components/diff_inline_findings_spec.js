import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffInlineFindings from '~/diffs/components/diff_inline_findings.vue';
import DiffInlineFindingsItem from '~/diffs/components/diff_inline_findings_item.vue';
import { NEW_CODE_QUALITY_FINDINGS } from '~/diffs/i18n';
import { multipleCodeQualityNoSast } from '../mock_data/diff_code_quality';

let wrapper;
const heading = () => wrapper.findByTestId('diff-inline-findings-heading');
const diffInlineFindingsItems = () => wrapper.findAllComponents(DiffInlineFindingsItem);

describe('DiffInlineFindings', () => {
  const createWrapper = () => {
    return shallowMountExtended(DiffInlineFindings, {
      propsData: {
        title: NEW_CODE_QUALITY_FINDINGS,
        findings: multipleCodeQualityNoSast.codeQuality,
      },
    });
  };

  it('renders the title correctly', () => {
    wrapper = createWrapper();
    expect(heading().text()).toBe(NEW_CODE_QUALITY_FINDINGS);
  });

  it('renders the correct number of DiffInlineFindingsItem components with correct props', () => {
    wrapper = createWrapper();
    expect(diffInlineFindingsItems()).toHaveLength(multipleCodeQualityNoSast.codeQuality.length);
    expect(diffInlineFindingsItems().wrappers[0].props('finding')).toEqual(
      wrapper.props('findings')[0],
    );
  });
});
