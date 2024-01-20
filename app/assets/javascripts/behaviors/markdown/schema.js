import { flatMap } from 'lodash';
import { Editor } from '@tiptap/vue-2';
import OrderedMap from 'orderedmap';
import { Schema } from '@tiptap/pm/model';
import * as extensions from '~/content_editor/extensions';

const { schema } = new Editor({ extensions: flatMap(extensions) });

const schemaSpec = { ...schema.spec };
schemaSpec.marks = OrderedMap.from(schemaSpec.marks).remove('span');
schemaSpec.nodes = OrderedMap.from(schemaSpec.nodes).remove('div').remove('pre');

export default new Schema(schemaSpec);
