import { GlSprintf, GlIntersperse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { useFakeDate } from 'helpers/fake_date';
import { findDd } from 'helpers/dl_locator_helper';
import { ACCESS_LEVEL_REF_PROTECTED, ACCESS_LEVEL_NOT_PROTECTED } from '~/ci/runner/constants';

import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerDetail from '~/ci/runner/components/runner_detail.vue';
import RunnerGroups from '~/ci/runner/components/runner_groups.vue';
import RunnerTags from '~/ci/runner/components/runner_tags.vue';
import RunnerTag from '~/ci/runner/components/runner_tag.vue';
import RunnerManagersDetail from '~/ci/runner/components/runner_managers_detail.vue';

import { runnerData, runnerWithGroupData } from '../mock_data';

const mockRunner = runnerData.data.runner;
const mockGroupRunner = runnerWithGroupData.data.runner;

describe('RunnerDetails', () => {
  let wrapper;
  const mockNow = '2021-01-15T12:00:00Z';
  const mockOneHourAgo = '2021-01-15T11:00:00Z';

  useFakeDate(mockNow);

  const findDetailGroups = () => wrapper.findComponent(RunnerGroups);
  const findRunnerManagersDetail = () => wrapper.findComponent(RunnerManagersDetail);

  const findDdContent = (label) => findDd(label, wrapper).text().replace(/\s+/g, ' ');

  const createComponent = ({ props = {}, stubs, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerDetails, {
      propsData: {
        ...props,
      },
      stubs: {
        RunnerDetail,
        ...stubs,
      },
    });
  };

  describe('Details tab', () => {
    describe.each`
      field                    | runner                                                             | expectedValue
      ${'Description'}         | ${{ description: 'My runner' }}                                    | ${'My runner'}
      ${'Description'}         | ${{ description: null }}                                           | ${'None'}
      ${'Last contact'}        | ${{ contactedAt: mockOneHourAgo }}                                 | ${'1 hour ago'}
      ${'Last contact'}        | ${{ contactedAt: null }}                                           | ${'Never contacted'}
      ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_REF_PROTECTED, runUntagged: true }}  | ${'Protected, Runs untagged jobs'}
      ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_REF_PROTECTED, runUntagged: false }} | ${'Protected'}
      ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_NOT_PROTECTED, runUntagged: true }}  | ${'Runs untagged jobs'}
      ${'Configuration'}       | ${{ accessLevel: ACCESS_LEVEL_NOT_PROTECTED, runUntagged: false }} | ${'None'}
      ${'Maximum job timeout'} | ${{ maximumTimeout: null }}                                        | ${'None'}
      ${'Maximum job timeout'} | ${{ maximumTimeout: 0 }}                                           | ${'0 seconds'}
      ${'Maximum job timeout'} | ${{ maximumTimeout: 59 }}                                          | ${'59 seconds'}
      ${'Maximum job timeout'} | ${{ maximumTimeout: 10 * 60 + 5 }}                                 | ${'10 minutes 5 seconds'}
      ${'Token expiry'}        | ${{ tokenExpiresAt: mockOneHourAgo }}                              | ${'1 hour ago'}
      ${'Token expiry'}        | ${{ tokenExpiresAt: null }}                                        | ${'Never expires'}
      ${'Runners'}             | ${{ managers: { count: 2 } }}                                      | ${`2 ${'Show details'}`}
    `('"$field" field', ({ field, runner, expectedValue }) => {
      beforeEach(() => {
        createComponent({
          props: {
            runner: {
              ...mockRunner,
              ...runner,
            },
          },
          stubs: {
            GlIntersperse,
            GlSprintf,
            TimeAgo,
            RunnerManagersDetail,
          },
        });
      });

      it(`displays expected value "${expectedValue}"`, () => {
        expect(findDdContent(field)).toBe(expectedValue);
      });
    });

    describe('"Tags" field', () => {
      const stubs = { RunnerTags, RunnerTag };

      it('displays expected value "tag-1 tag-2"', () => {
        createComponent({
          props: {
            runner: { ...mockRunner, tagList: ['tag-1', 'tag-2'] },
          },
          stubs,
        });

        expect(findDdContent('Tags')).toContain('tag-1');
        expect(findDdContent('Tags')).toContain('tag-2');
      });

      it('displays "None" when runner has no tags', () => {
        createComponent({
          props: {
            runner: { ...mockRunner, tagList: [] },
          },
          stubs,
        });

        expect(findDdContent('Tags')).toBe('None');
      });
    });

    describe('"Runners" field', () => {
      it('displays runner managers count of $count', () => {
        createComponent({
          props: {
            runner: mockRunner,
          },
        });

        expect(findRunnerManagersDetail().props('runner')).toEqual(mockRunner);
      });
    });

    describe('Group runners', () => {
      beforeEach(() => {
        createComponent({
          props: {
            runner: mockGroupRunner,
          },
        });
      });

      it('Shows a group runner details', () => {
        expect(findDetailGroups().props('runner')).toEqual(mockGroupRunner);
      });
    });
  });
});
