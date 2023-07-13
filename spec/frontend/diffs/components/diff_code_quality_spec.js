import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffCodeQuality from '~/diffs/components/diff_code_quality.vue';
import DiffCodeQualityItem from '~/diffs/components/diff_code_quality_item.vue';
import { NEW_CODE_QUALITY_FINDINGS, NEW_SAST_FINDINGS } from '~/diffs/i18n';
import {
  multipleCodeQualityNoSast,
  multipleSastNoCodeQuality,
  multipleFindingsArrSastScale,
} from '../mock_data/diff_code_quality';

let wrapper;

const diffItems = () => wrapper.findAllComponents(DiffCodeQualityItem);
const findCodeQualityHeading = () => wrapper.findByTestId(`diff-codequality-findings-heading`);
const findSastHeading = () => wrapper.findByTestId(`diff-sast-findings-heading`);

describe('DiffCodeQuality', () => {
  const createWrapper = (findings, mountFunction = mountExtended) => {
    return mountFunction(DiffCodeQuality, {
      propsData: {
        expandedLines: [],
        codeQuality: findings.codeQuality,
        sast: findings.sast,
      },
    });
  };

  it('hides details and throws hideCodeQualityFindings event on close click', async () => {
    wrapper = createWrapper(multipleCodeQualityNoSast);
    expect(wrapper.findByTestId('diff-codequality').exists()).toBe(true);

    await wrapper.findByTestId('diff-codequality-close').trigger('click');
    expect(wrapper.emitted('hideCodeQualityFindings').length).toBe(1);
  });

  it('renders heading and correct amount of list items for codequality array and their description', () => {
    wrapper = createWrapper(multipleCodeQualityNoSast, shallowMountExtended);

    expect(findCodeQualityHeading().text()).toEqual(NEW_CODE_QUALITY_FINDINGS);

    expect(diffItems()).toHaveLength(multipleCodeQualityNoSast.codeQuality.length);
    expect(diffItems().at(0).props().finding).toEqual(multipleCodeQualityNoSast.codeQuality[0]);
  });

  it('does not render codeQuality section when codeQuality array is empty', () => {
    wrapper = createWrapper(multipleSastNoCodeQuality, shallowMountExtended);
    expect(findCodeQualityHeading().exists()).toBe(false);
  });

  it('renders heading and correct amount of list items for sast array and their description', () => {
    wrapper = createWrapper(multipleSastNoCodeQuality, shallowMountExtended);

    expect(findSastHeading().text()).toEqual(NEW_SAST_FINDINGS);
    expect(diffItems()).toHaveLength(multipleSastNoCodeQuality.sast.length);
    expect(diffItems().at(0).props().finding).toEqual(multipleFindingsArrSastScale[0]);
  });

  it('does not render sast section when sast array is empty', () => {
    wrapper = createWrapper(multipleCodeQualityNoSast, shallowMountExtended);
    expect(findSastHeading().exists()).toBe(false);
  });
});
