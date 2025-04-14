import { createAsyncTabContentWrapper } from './index';

export default {
  title: 'usage_quotas/async_tab_content_wrapper',
};

const Template = (component) => {
  const AsyncTabComponent = () => createAsyncTabContentWrapper(component);

  return {
    render(h) {
      return h(AsyncTabComponent);
    },
  };
};

export const Default = () =>
  Template(
    new Promise((resolve) => {
      setTimeout(() => {
        resolve({ template: '<div>Loaded!</div>' });
      }, 1000);
    }),
  );

export const Error = () =>
  Template(
    new Promise((resolve, reject) => {
      setTimeout(() => {
        reject(Error('null'));
      }, 1000);
    }),
  );
