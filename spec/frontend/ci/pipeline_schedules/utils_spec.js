import { updateScheduleNodes } from '~/ci/pipeline_schedules/utils';
import { mockScheduleUpdateResponse, mockSchedules } from './mock_data';

describe('Pipeline schedule utility functions', () => {
  describe('updateScheduleNodes', () => {
    it('updates the schedule pipeline status from running to passed', () => {
      const unchangedSchedule = mockSchedules[0];

      expect(mockSchedules[1].lastPipeline.detailedStatus.group).toBe('running');

      const updatedSchedules = updateScheduleNodes(
        mockSchedules,
        mockScheduleUpdateResponse.data.ciPipelineScheduleStatusUpdated,
      );

      expect(updatedSchedules[0]).toEqual(unchangedSchedule);
      expect(updatedSchedules[1].lastPipeline.detailedStatus.group).toBe('success');
    });
  });
});
