import { GlSprintf, GlIntersperse } from '@gitlab/ui';
import { createWrapper, ErrorWrapper } from '@vue/test-utils';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { useFakeDate } from 'helpers/fake_date';
import { ACCESS_LEVEL_REF_PROTECTED, ACCESS_LEVEL_NOT_PROTECTED } from '~/runner/constants';

import RunnerDetails from '~/runner/components/runner_details.vue';
import RunnerDetail from '~/runner/components/runner_detail.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerDetails', () => {
  let wrapper;
  const mockNow = '2021-01-15T12:00:00Z';
  const mockOneHourAgo = '2021-01-15T11:00:00Z';

  useFakeDate(mockNow);

  /**
   * Find the definition (<dd>) that corresponds to this term (<dt>)
   * @param {string} dtLabel - Label for this value
   * @returns Wrapper
   */
  const findDd = (dtLabel) => {
    const dt = wrapper.findByText(dtLabel).element;
    const dd = dt.nextElementSibling;
    if (dt.tagName === 'DT' && dd.tagName === 'DD') {
      return createWrapper(dd, {});
    }
    return ErrorWrapper(dtLabel);
  };

  const createComponent = ({ runner = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerDetails, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
      },
      stubs: {
        GlIntersperse,
        GlSprintf,
        TimeAgo,
        RunnerDetail,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    field                    | runner                                                             | expectedValue
    ${'Description'}         | ${{ description: 'My runner' }}                                    | ${'My runner'}
    ${'Description'}         | ${{ description: null }}                                           | ${'None'}
    ${'Last contact'}        | ${{ contactedAt: mockOneHourAgo }}                                 | ${'1 hour ago'}
    ${'Last contact'}        | ${{ contactedAt: null }}                                           | ${'Never contacted'}
    ${'Version'}             | ${{ version: '12.3' }}                                             | ${'12.3'}
    ${'Version'}             | ${{ version: null }}                                               | ${'None'}
    ${'IP Address'}          | ${{ ipAddress: '127.0.0.1' }}                                      | ${'127.0.0.1'}
    ${'IP Address'}          | ${{ ipAddress: null }}                                             | ${'None'}
    ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_REF_PROTECTED, runUntagged: true }}  | ${'Protected, Runs untagged jobs'}
    ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_REF_PROTECTED, runUntagged: false }} | ${'Protected'}
    ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_NOT_PROTECTED, runUntagged: true }}  | ${'Runs untagged jobs'}
    ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_NOT_PROTECTED, runUntagged: false }} | ${'None'}
    ${'Maximum job timeout'} | ${{ maximumTimeout: null }}                                        | ${'None'}
    ${'Maximum job timeout'} | ${{ maximumTimeout: 0 }}                                           | ${'0 seconds'}
    ${'Maximum job timeout'} | ${{ maximumTimeout: 59 }}                                          | ${'59 seconds'}
    ${'Maximum job timeout'} | ${{ maximumTimeout: 10 * 60 + 5 }}                                 | ${'10 minutes 5 seconds'}
  `('"$field" field', ({ field, runner, expectedValue }) => {
    beforeEach(() => {
      createComponent({
        runner,
      });
    });

    it(`displays expected value "${expectedValue}"`, () => {
      expect(findDd(field).text()).toBe(expectedValue);
    });
  });

  describe('"Tags" field', () => {
    it('displays expected value "tag-1 tag-2"', () => {
      createComponent({
        runner: { tagList: ['tag-1', 'tag-2'] },
        mountFn: mountExtended,
      });

      expect(findDd('Tags').text().replace(/\s+/g, ' ')).toBe('tag-1 tag-2');
    });

    it('displays "None" when runner has no tags', () => {
      createComponent({
        runner: { tagList: [] },
        mountFn: mountExtended,
      });

      expect(findDd('Tags').text().replace(/\s+/g, ' ')).toBe('None');
    });
  });
});
