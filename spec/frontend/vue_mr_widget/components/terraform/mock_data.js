export const invalidPlan = {};

export const validPlan = {
  create: 10,
  update: 20,
  delete: 30,
  job_name: 'Plan Changes',
  job_path: '/path/to/ci/logs/1',
};

export const plans = {
  '1': validPlan,
  '2': invalidPlan,
  '3': {
    create: 1,
    update: 2,
    delete: 3,
    job_name: 'Plan 3',
    job_path: '/path/to/ci/logs/3',
  },
};
