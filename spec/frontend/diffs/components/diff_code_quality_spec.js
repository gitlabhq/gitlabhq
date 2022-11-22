import { GlIcon } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiffCodeQuality from '~/diffs/components/diff_code_quality.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/reports/codequality_report/constants';
import { multipleFindingsArr } from '../mock_data/diff_code_quality';

let wrapper;

const findIcon = () => wrapper.findComponent(GlIcon);

describe('DiffCodeQuality', () => {
  afterEach(() => {
    wrapper.destroy();
  });

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

  it('renders correct amount of list items for codequality array and their description', async () => {
    wrapper = createWrapper(multipleFindingsArr);
    const listItems = wrapper.findAll('li');

    expect(wrapper.findAll('li').length).toBe(5);

    listItems.wrappers.map((e, i) => {
      return expect(e.text()).toEqual(multipleFindingsArr[i].description);
    });
  });

  it.each`
    severity
    ${'info'}
    ${'minor'}
    ${'major'}
    ${'critical'}
    ${'blocker'}
    ${'unknown'}
  `('shows icon for $severity degradation', ({ severity }) => {
    wrapper = createWrapper([{ severity }], shallowMountExtended);

    expect(findIcon().exists()).toBe(true);

    expect(findIcon().attributes()).toMatchObject({
      class: `codequality-severity-icon ${SEVERITY_CLASSES[severity]}`,
      name: SEVERITY_ICONS[severity],
      size: '12',
    });
  });
});
