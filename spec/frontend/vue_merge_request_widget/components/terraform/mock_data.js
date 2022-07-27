export const invalidPlanWithName = {
  job_name: 'Invalid Plan',
  job_path: '/path/to/ci/logs/3',
  tf_report_error: 'api_error',
};

export const invalidPlanWithoutName = {
  tf_report_error: 'invalid_json_format',
};

export const validPlanWithName = {
  create: 10,
  update: 20,
  delete: 30,
  job_name: 'Valid Plan',
  job_path: '/path/to/ci/logs/1',
};

export const validPlanWithoutName = {
  create: 10,
  update: 20,
  delete: 30,
  job_path: '/path/to/ci/logs/2',
};

export const plans = {
  invalid_plan_one: invalidPlanWithName,
  invalid_plan_two: invalidPlanWithoutName,
  valid_plan_one: validPlanWithName,
  valid_plan_two: validPlanWithoutName,
};
