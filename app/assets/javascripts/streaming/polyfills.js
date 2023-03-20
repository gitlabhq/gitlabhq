import { createReadableStreamWrapper } from '@mattiasbuelens/web-streams-adapter';
import { ReadableStream as PolyfillReadableStream } from 'web-streams-polyfill';

// TODO: remove this when our WebStreams API reaches 100% support
export const toPolyfillReadable = createReadableStreamWrapper(PolyfillReadableStream);
