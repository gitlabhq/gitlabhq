import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffCodeQualityItem from '~/diffs/components/diff_code_quality_item.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import { multipleFindingsArr } from '../mock_data/diff_code_quality';

let wrapper;

const findIcon = () => wrapper.findComponent(GlIcon);
const findButton = () => wrapper.findComponent(GlLink);
const findDescriptionPlainText = () => wrapper.findByTestId('description-plain-text');
const findDescriptionLinkSection = () => wrapper.findByTestId('description-button-section');

describe('DiffCodeQuality', () => {
  const createWrapper = ({ glFeatures = {} } = {}) => {
    return shallowMountExtended(DiffCodeQualityItem, {
      propsData: {
        finding: multipleFindingsArr[0],
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
      class: `codequality-severity-icon ${SEVERITY_CLASSES[multipleFindingsArr[0].severity]}`,
      name: SEVERITY_ICONS[multipleFindingsArr[0].severity],
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
      expect(findDescriptionPlainText().text()).toContain(multipleFindingsArr[0].severity);
      expect(findDescriptionPlainText().text()).toContain(multipleFindingsArr[0].description);
    });
  });

  describe('with codeQualityInlineDrawer flag true', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        glFeatures: {
          codeQualityInlineDrawer: true,
        },
      });
    });

    it('should render severity as plain text', () => {
      expect(findDescriptionLinkSection().text()).toContain(multipleFindingsArr[0].severity);
    });

    it('should render button with description text', () => {
      expect(findButton().text()).toContain(multipleFindingsArr[0].description);
    });
  });
});
