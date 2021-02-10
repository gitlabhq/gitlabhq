export const createJestExecutionWatcher = () => {
  let isExecuting = false;

  beforeAll(() => {
    isExecuting = true;
  });
  afterAll(() => {
    isExecuting = false;
  });

  return () => isExecuting;
};
