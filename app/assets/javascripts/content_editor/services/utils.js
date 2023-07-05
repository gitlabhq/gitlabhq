import axios from 'axios';
import { memoize } from 'lodash';

export const hasSelection = (tiptapEditor) => {
  const { from, to } = tiptapEditor.state.selection;

  return from < to;
};

export const clamp = (n, min, max) => Math.max(Math.min(n, max), min);

export const memoizedGet = memoize(async (path) => {
  const { data } = await axios(path, { responseType: 'blob' });
  return data.text();
});
