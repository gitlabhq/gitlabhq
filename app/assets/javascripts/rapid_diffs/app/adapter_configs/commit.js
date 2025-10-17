import { VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';

export const adapters = {
  ...VIEWER_ADAPTERS,
  text_inline: [...VIEWER_ADAPTERS.text_inline],
  text_parallel: [...VIEWER_ADAPTERS.text_parallel],
};
