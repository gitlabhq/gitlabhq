import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffInlineFindingsItem from '~/diffs/components/diff_inline_findings_item.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import { multipleFindingsArrCodeQualityScale } from '../mock_data/diff_code_quality';

let wrapper;

const [codeQualityFinding] = multipleFindingsArrCodeQualityScale;
const findIcon = () => wrapper.findComponent(GlIcon);
const findButton = () => wrapper.findComponent(GlLink);
const findDescriptionPlainText = () => wrapper.findByTestId('description-plain-text');
const findDescriptionLinkSection = () => wrapper.findByTestId('description-button-section');

describe('DiffCodeQuality', () => {
  const createWrapper = ({ glFeatures = {}, link = true } = {}) => {
    return shallowMountExtended(DiffInlineFindingsItem, {
      propsData: {
        finding: codeQualityFinding,
        link,
      },
      provide: {
        glFeatures,
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

  describe('with codeQualityInlineDrawer flag false', () => {
    it('should render severity + description in plain text', () => {
      wrapper = createWrapper({
        glFeatures: {
          codeQualityInlineDrawer: false,
        },
      });
      expect(findDescriptionPlainText().text()).toContain(codeQualityFinding.severity);
      expect(findDescriptionPlainText().text()).toContain(codeQualityFinding.description);
    });
  });

  describe('with codeQualityInlineDrawer flag true', () => {
    const [{ description, severity }] = multipleFindingsArrCodeQualityScale;
    const renderedText = `${severity} - ${description}`;
    it('when link prop is true, should render gl-link', () => {
      wrapper = createWrapper({
        glFeatures: {
          codeQualityInlineDrawer: true,
        },
      });

      expect(findButton().exists()).toBe(true);
      expect(findButton().text()).toBe(renderedText);
    });

    it('when link prop is false, should not render gl-link', () => {
      wrapper = createWrapper({
        glFeatures: {
          codeQualityInlineDrawer: true,
        },
        link: false,
      });

      expect(findButton().exists()).toBe(false);
      expect(findDescriptionLinkSection().text()).toBe(renderedText);
    });
  });
});
