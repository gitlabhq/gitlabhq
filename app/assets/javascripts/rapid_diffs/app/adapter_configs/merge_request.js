import { HEADER_ADAPTERS, VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import { viewedAdapter } from '~/rapid_diffs/adapters/viewed';

const MR_HEADER_ADAPTERS = [...HEADER_ADAPTERS, viewedAdapter];

export const adapters = {
  text_inline: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.text_inline.slice(HEADER_ADAPTERS.length),
  ],
  text_parallel: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.text_parallel.slice(HEADER_ADAPTERS.length),
  ],
  image: [...MR_HEADER_ADAPTERS, ...VIEWER_ADAPTERS.image.slice(HEADER_ADAPTERS.length)],
  no_preview: [...MR_HEADER_ADAPTERS],
};
