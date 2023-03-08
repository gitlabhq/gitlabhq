import emptySvg from '@gitlab/svgs/dist/illustrations/security-dashboard-empty-state.svg';
import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { __ } from '~/locale';

export const ERROR_FETCHING_DATA_HEADER = __('Could not get the data properly');
export const ERROR_FETCHING_DATA_DESCRIPTION = __(
  'Please try and refresh the page. If the problem persists please contact support.',
);

/**
 * This function takes a Component and extends it with data from the `parseData` function.
 * The data will be made available through `props` and `proivde`.
 * If the `parseData` throws, the `GlEmptyState` will be returned.
 * @param  {Component} Component a component to render
 * @param  {Object} options
 * @param  {Function} options.parseData a function to parse `data`
 * @param  {Object} options.data an object to pass to `parseData`
 * @param  {Boolean} options.shouldLog to tell whether to log any thrown error by `parseData` to Sentry
 * @param  {Object} options.props to override passed `props` data
 * @param  {Object} options.provide to override passed `provide` data
 * @param  {*} ...options the remaining options will be passed as properties to `createElement`
 * @return {Component} a Vue component to render, either the GlEmptyState or the extended Component
 */
export default function ensureData(Component, options = {}) {
  const { parseData, data, shouldLog = false, props, provide, ...rest } = options;
  try {
    const parsedData = parseData(data);
    return {
      provide: { ...parsedData, ...provide },
      render(createElement) {
        return createElement(Component, {
          props: { ...parsedData, ...props },
          ...rest,
        });
      },
    };
  } catch (error) {
    if (shouldLog) {
      Sentry.captureException(error);
    }

    return {
      functional: true,
      render(createElement) {
        return createElement(GlEmptyState, {
          props: {
            title: ERROR_FETCHING_DATA_HEADER,
            description: ERROR_FETCHING_DATA_DESCRIPTION,
            svgPath: `data:image/svg+xml;utf8,${encodeURIComponent(emptySvg)}`,
          },
        });
      },
    };
  }
}
