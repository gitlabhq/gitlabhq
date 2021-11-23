import { memoize } from 'lodash';

import { uuids } from './uuids';

export const create = memoize((options = {}) => {
  const id = uuids()[0];

  return {
    id,
    observer: new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        entry.target.dispatchEvent(
          new CustomEvent(`IntersectionUpdate`, { detail: { entry, observer: id } }),
        );

        if (entry.isIntersecting) {
          entry.target.dispatchEvent(
            new CustomEvent(`IntersectionAppear`, { detail: { observer: id } }),
          );
        } else {
          entry.target.dispatchEvent(
            new CustomEvent(`IntersectionDisappear`, { detail: { observer: id } }),
          );
        }
      });
    }, options),
  };
});
