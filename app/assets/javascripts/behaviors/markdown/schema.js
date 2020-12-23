import { Schema } from 'prosemirror-model';
import editorExtensions from './editor_extensions';

const nodes = editorExtensions
  .filter((extension) => extension.type === 'node')
  .reduce(
    (ns, { name, schema }) => ({
      ...ns,
      [name]: schema,
    }),
    {},
  );

const marks = editorExtensions
  .filter((extension) => extension.type === 'mark')
  .reduce(
    (ms, { name, schema }) => ({
      ...ms,
      [name]: schema,
    }),
    {},
  );

export default new Schema({ nodes, marks });
