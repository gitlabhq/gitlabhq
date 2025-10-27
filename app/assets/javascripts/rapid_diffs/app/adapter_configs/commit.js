import { VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import {
  inlineDiscussionsAdapter,
  parallelDiscussionsAdapter,
} from '~/rapid_diffs/adapters/discussions';

export const adapters = {
  ...VIEWER_ADAPTERS,
  text_inline: [...VIEWER_ADAPTERS.text_inline, inlineDiscussionsAdapter],
  text_parallel: [...VIEWER_ADAPTERS.text_parallel, parallelDiscussionsAdapter],
};
