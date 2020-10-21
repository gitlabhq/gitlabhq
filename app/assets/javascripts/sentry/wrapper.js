// Temporarily commented out to investigate performance: https://gitlab.com/gitlab-org/gitlab/-/issues/251179
// export * from '@sentry/browser';

export function init(...args) {
  return args;
}

export function setUser(...args) {
  return args;
}

export function captureException(...args) {
  return args;
}

export function captureMessage(...args) {
  return args;
}

export function withScope(fn) {
  fn({
    setTag(...args) {
      return args;
    },
  });
}
