import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffInlineFindingsItem from '~/diffs/components/diff_inline_findings_item.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import { multipleFindingsArrCodeQualityScale } from '../mock_data/inline_findings';

let wrapper;

const [codeQualityFinding] = multipleFindingsArrCodeQualityScale;
const findIcon = () => wrapper.findComponent(GlIcon);
const findDescriptionPlainText = () => wrapper.findByTestId('description-plain-text');

describe('DiffCodeQuality', () => {
  const createWrapper = () => {
    return shallowMountExtended(DiffInlineFindingsItem, {
      propsData: {
        finding: codeQualityFinding,
      },
    });
  };

  it('shows icon for given degradation', () => {
    wrapper = createWrapper();
    expect(findIcon().exists()).toBe(true);

    expect(findIcon().attributes()).toMatchObject({
      class: `inline-findings-severity-icon ${SEVERITY_CLASSES[codeQualityFinding.severity]}`,
      name: SEVERITY_ICONS[codeQualityFinding.severity],
      size: '12',
    });
  });

  it('should render severity + description in plain text', () => {
    wrapper = createWrapper();
    expect(findDescriptionPlainText().text()).toContain(codeQualityFinding.severity);
    expect(findDescriptionPlainText().text()).toContain(codeQualityFinding.description);
  });
});
