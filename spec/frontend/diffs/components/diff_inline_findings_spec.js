import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffInlineFindings from '~/diffs/components/diff_inline_findings.vue';
import DiffCodeQualityItem from '~/diffs/components/diff_code_quality_item.vue';
import { NEW_CODE_QUALITY_FINDINGS } from '~/diffs/i18n';
import { multipleCodeQualityNoSast } from '../mock_data/diff_code_quality';

let wrapper;
const heading = () => wrapper.findByTestId('diff-inline-findings-heading');
const diffCodeQualityItems = () => wrapper.findAllComponents(DiffCodeQualityItem);

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

  it('renders the correct number of DiffCodeQualityItem components with correct props', () => {
    wrapper = createWrapper();
    expect(diffCodeQualityItems()).toHaveLength(multipleCodeQualityNoSast.codeQuality.length);
    expect(diffCodeQualityItems().wrappers[0].props('finding')).toEqual(
      wrapper.props('findings')[0],
    );
  });
});
