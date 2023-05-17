import { Schema } from '@tiptap/pm/model';
import editorExtensions from './editor_extensions';

const nodes = editorExtensions.nodes.reduce(
  (ns, { name, schema }) => ({
    ...ns,
    [name]: schema,
  }),
  {},
);

const marks = editorExtensions.marks.reduce(
  (ms, { name, schema }) => ({
    ...ms,
    [name]: schema,
  }),
  {},
);

export default new Schema({ nodes, marks });
