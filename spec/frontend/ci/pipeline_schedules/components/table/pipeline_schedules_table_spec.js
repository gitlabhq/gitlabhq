import { GlTable } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineSchedulesTable from '~/ci/pipeline_schedules/components/table/pipeline_schedules_table.vue';
import {
  TH_DESCRIPTION_TEST_ID,
  TH_TARGET_TEST_ID,
  TH_NEXT_TEST_ID,
} from '~/ci/pipeline_schedules/constants';
import { mockPipelineScheduleNodes, mockPipelineScheduleCurrentUser } from '../../mock_data';

describe('Pipeline schedules table', () => {
  let wrapper;

  const defaultProps = {
    schedules: mockPipelineScheduleNodes,
    currentUser: mockPipelineScheduleCurrentUser,
  };

  const createComponent = (props = defaultProps) => {
    wrapper = mountExtended(PipelineSchedulesTable, {
      propsData: {
        ...props,
        sortBy: 'ID',
        sortDesc: true,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findScheduleDescription = () => wrapper.findByTestId('pipeline-schedule-description');
  const findCron = () => wrapper.findByTestId('pipeline-schedule-cron');
  const findCronTimezone = () => wrapper.findByTestId('pipeline-schedule-cron-timezone');

  describe('defaults', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('displays schedule description', () => {
      expect(findScheduleDescription().text()).toBe('pipeline schedule');
    });

    it('displays cron and cron timezone values', () => {
      expect(findCron().text()).toBe(defaultProps.schedules[0].cron);
      expect(findCronTimezone().text()).toBe(defaultProps.schedules[0].cronTimezone);
    });
  });

  describe('sorting', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it.each`
      sortValue             | sortBy           | sortDesc
      ${'DESCRIPTION_ASC'}  | ${'description'} | ${false}
      ${'DESCRIPTION_DESC'} | ${'description'} | ${true}
      ${'REF_ASC'}          | ${'target'}      | ${false}
      ${'REF_DESC'}         | ${'target'}      | ${true}
      ${'NEXT_RUN_AT_ASC'}  | ${'next'}        | ${false}
      ${'NEXT_RUN_AT_DESC'} | ${'next'}        | ${true}
    `(
      'emits sort data in expected format for sortValue $sortValue',
      ({ sortValue, sortBy, sortDesc }) => {
        findTable().vm.$emit('sort-changed', { sortBy, sortDesc });

        expect(wrapper.emitted('update-sorting')[0]).toEqual([sortValue, sortBy, sortDesc]);
      },
    );

    it('emits no update-sorting event when called with unsortable column', () => {
      findTable().vm.$emit('sort-changed', { sortBy: 'actions', sortDesc: false });

      expect(wrapper.emitted('update-sorting')).toBeUndefined();
    });

    it('emits no update-sorting event when called with unknown column', () => {
      findTable().vm.$emit('sort-changed', { sortBy: 'not-defined-never', sortDesc: false });

      expect(wrapper.emitted('update-sorting')).toBeUndefined();
    });
  });

  describe('sorting the pipeline schedules table by column', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it.each`
      description      | selector
      ${'description'} | ${TH_DESCRIPTION_TEST_ID}
      ${'target'}      | ${TH_TARGET_TEST_ID}
      ${'next'}        | ${TH_NEXT_TEST_ID}
    `('updates sort with new direction when sorting by $description', async ({ selector }) => {
      const [[attr, value]] = Object.entries(selector);
      const columnHeader = () => wrapper.find(`[${attr}="${value}"]`);
      expect(columnHeader().attributes('aria-sort')).toBe('none');
      columnHeader().trigger('click');
      await waitForPromises();
      expect(columnHeader().attributes('aria-sort')).toBe('ascending');
      columnHeader().trigger('click');
      await waitForPromises();
      expect(columnHeader().attributes('aria-sort')).toBe('descending');
    });
  });
});
