export const allCheck = (state) => {
  const checks = Object.values(state.checks);

  if (checks.some((check) => check.isLoading)) {
    return { isLoading: true };
  }

  const invalidCheck = checks.find((check) => !check.isValid);
  const isValid = !invalidCheck;
  const message = !invalidCheck ? '' : invalidCheck.message;

  return {
    isLoading: false,
    isValid,
    message,
  };
};
