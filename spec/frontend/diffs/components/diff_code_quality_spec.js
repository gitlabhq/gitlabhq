import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffCodeQuality from '~/diffs/components/diff_code_quality.vue';
import DiffCodeQualityItem from '~/diffs/components/diff_code_quality_item.vue';
import { NEW_CODE_QUALITY_FINDINGS } from '~/diffs/i18n';
import { multipleFindingsArr } from '../mock_data/diff_code_quality';

let wrapper;

const diffItems = () => wrapper.findAllComponents(DiffCodeQualityItem);
const findHeading = () => wrapper.findByTestId(`diff-codequality-findings-heading`);

describe('DiffCodeQuality', () => {
  const createWrapper = (codeQuality, mountFunction = mountExtended) => {
    return mountFunction(DiffCodeQuality, {
      propsData: {
        expandedLines: [],
        codeQuality,
      },
    });
  };

  it('hides details and throws hideCodeQualityFindings event on close click', async () => {
    wrapper = createWrapper(multipleFindingsArr);
    expect(wrapper.findByTestId('diff-codequality').exists()).toBe(true);

    await wrapper.findByTestId('diff-codequality-close').trigger('click');
    expect(wrapper.emitted('hideCodeQualityFindings').length).toBe(1);
  });

  it('renders heading and correct amount of list items for codequality array and their description', () => {
    wrapper = createWrapper(multipleFindingsArr, shallowMountExtended);

    expect(findHeading().text()).toEqual(NEW_CODE_QUALITY_FINDINGS);

    expect(diffItems()).toHaveLength(multipleFindingsArr.length);
    expect(diffItems().at(0).props().finding).toEqual(multipleFindingsArr[0]);
  });
});
