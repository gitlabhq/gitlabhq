export const updateScheduleNodes = (schedules = [], updatedSchedule = {}) => {
  return schedules.map((schedule) => {
    if (schedule.id === updatedSchedule.id) {
      return {
        ...schedule,
        lastPipeline: updatedSchedule.lastPipeline,
      };
    }

    return schedule;
  });
};
